require 'rawr_environment'
puts "Running in #{Rawr::ruby_environment}"

require 'fileutils'
require 'options'
require 'rbconfig'
require 'platform'
require 'generator'
require 'jar_builder'

def file_is_newer?(source, target)
  !File.exists?(target) || (File.mtime(target) < File.mtime(source))
end

Rawr::Options.load_configuration
RAWR_OPTS = Rawr::Options.data

namespace :rawr do
  
  desc "Build all data jars"
  task :build_data_jars => :prepare do
    RAWR_OPTS.jars_to_build.each do |jar_builder|
      jar_builder.build
    end
  end
  
  desc "Removes generated content"
  task :clean do
    FileUtils.remove_dir(RAWR_OPTS.output_dir) if File.directory? RAWR_OPTS.output_dir
  end

  desc "Creates the output directory and sub-directories, reads in configuration data"
  task :prepare do
    FileUtils.mkdir_p RAWR_OPTS.output_dir
    FileUtils.mkdir_p RAWR_OPTS.compile_dir
    FileUtils.mkdir_p RAWR_OPTS.jar_output_dir
    FileUtils.mkdir_p RAWR_OPTS.windows_output_dir
    FileUtils.mkdir_p RAWR_OPTS.osx_output_dir
    FileUtils.mkdir_p RAWR_OPTS.linux_output_dir
  end
  
  desc 'Compiles all the Java source and Ruby source files in the source_dirs entry in the build_configuration.rb file.'
  task :compile => ['rawr:compile_java_classes', 'rawr:compile_ruby_classes', 'rawr:copy_other_file_in_source_dirs']
  
  desc "Compiles the Java source files specified in the source_dirs entry"
  task :compile_java_classes => "rawr:prepare" do
    delimiter = Platform.instance.argument_delimiter
    
    java_source_file_list = RAWR_OPTS.source_dirs.inject([]) do |list, directory|
      list << Dir.glob("#{directory}/**/*.java").
        reject{|file| File.directory?(file)}.
        map!{|file| directory ? file.sub("#{directory}/", '') : file}.
        reject{|file| RAWR_OPTS.source_exclude_filter.inject(false) {|rejected, filter| (file =~ filter) || rejected} }.
        map!{|file| OpenStruct.new(:file => file, :directory => directory)}
    end.flatten!
    
    unless java_source_file_list.empty?
      FileUtils.mkdir_p("#{RAWR_OPTS.compile_dir}/META-INF")

      java_source_file_list.each do |data|
        file = data.file
        directory = data.directory
        target_file = "#{RAWR_OPTS.compile_dir}/#{file.sub(/\.java$/, '.class')}"

#        if !File.exists?(target_file) || (File.mtime(target_file) < File.mtime("#{directory}/#{file}"))
        if file_is_newer?("#{directory}/#{file}", target_file)
          sh "javac -target #{RAWR_OPTS.target_jvm_version} -cp \"#{(RAWR_OPTS.classpath + RAWR_OPTS.source_dirs).join(delimiter)}\" -sourcepath \"#{RAWR_OPTS.source_dirs.join(delimiter)}\" -d \"#{RAWR_OPTS.compile_dir}\" \"#{directory}/#{file}\""
        end
      end
    end
  end
  
  desc "Compiles the Ruby source files specified in the source_dirs entry"
  task :compile_ruby_classes => "rawr:prepare" do
    require 'command'
    Rawr::Command.compile_ruby_dirs(RAWR_OPTS.source_dirs, RAWR_OPTS.compile_dir, RAWR_OPTS.jruby_jar, RAWR_OPTS.source_exclude_filter, RAWR_OPTS.target_jvm_version, !RAWR_OPTS.compile_ruby_files)
  end

  desc "Compiles the Duby source files specified in the source_dirs entry"
  task :compile_duby_classes => "rawr:prepare" do
    ruby_source_file_list = RAWR_OPTS.source_dirs.inject([]) do |list, directory|
      list << Dir.glob("#{directory}/**/*.duby").
            reject{|file| File.directory?(file)}.
            map!{|file| directory ? file.sub("#{directory}/", '') : file}.
            reject{|file| RAWR_OPTS.source_exclude_filter.inject(false) {|rejected, filter| (file =~ filter) || rejected} }.
            map!{|file| OpenStruct.new(:file => file, :directory => directory)}
    end.flatten!

    ruby_source_file_list.each do |data|
      file = data.file
      directory = data.directory

      relative_dir, name = File.split(file)

      if name[0..0] =~ /\d/
        processed_file = relative_dir + '/$' + name
      else
        processed_file = file
      end

      processed_file = processed_file.sub(/\.duby$/, '.class')
      target_file = "#{RAWR_OPTS.compile_dir}/#{processed_file}"

      if file_is_newer?("#{directory}/#{file}", target_file)
        FileUtils.mkdir_p(File.dirname("#{RAWR_OPTS.compile_dir}/#{processed_file}"))

        sh "dubyc -J-classpath #{directory}/#{file}"
        File.move("#{directory}/#{processed_file}", "#{RAWR_OPTS.compile_dir}/#{processed_file}")
      end
    end
  end

  task :copy_other_file_in_source_dirs => "rawr:prepare" do
    non_source_file_list = RAWR_OPTS.source_dirs.inject([]) do |list, directory|
      list << Dir.glob("#{directory}/**/*").
            reject{|file| File.directory?(file)}.
            map!{|file| directory ? file.sub("#{directory}/", '') : file}.
            reject{|file| RAWR_OPTS.source_exclude_filter.inject(false) {|rejected, filter| (file =~ filter) || rejected} }.
            reject{|file| file =~ /\.rb|\.java|\.class/}.
            map!{|file| OpenStruct.new(:file => file, :directory => directory)}
    end.flatten!
    
    non_source_file_list.each do |data|
      file = data.file
      directory = data.directory
      puts "Copying non-source file #{file} to #{RAWR_OPTS.compile_dir}/#{file}"
      FileUtils.mkdir_p(File.dirname("#{RAWR_OPTS.compile_dir}/#{file}"))
      if file_is_newer?("#{directory}/#{file}", "#{RAWR_OPTS.compile_dir}/#{file}")
        File.copy("#{directory}/#{file}", "#{RAWR_OPTS.compile_dir}/#{file}")
      end
    end
  end
  
  desc "Uses compiled output and creates an executable jar file."
  task :jar => ["rawr:compile", "rawr:build_data_jars"] do
    Rawr::Generator.create_manifest_file(RAWR_OPTS)
    Rawr::Generator.create_run_config_file(RAWR_OPTS)
    archive_name = "#{RAWR_OPTS.project_name}.jar"
    RAWR_OPTS.compile_dir
    Rawr::JarBuilder.new(archive_name, :directory => RAWR_OPTS.compile_dir).build

    # Re-add the manifest file using the jar utility so that it
    # is processed as a manifest file and thus signing will work.
    `jar ufm #{RAWR_OPTS.jar_output_dir}/#{archive_name} #{RAWR_OPTS.compile_dir}/META-INF/MANIFEST.MF`

    (RAWR_OPTS.classpath + RAWR_OPTS.files_to_copy).each do |file|
      destination_file = file.gsub('../', '')
      FileUtils.mkdir_p(File.dirname("#{RAWR_OPTS.jar_output_dir}/#{destination_file}"))
      File.copy(file, "#{RAWR_OPTS.jar_output_dir}/#{destination_file}")
    end
  end
  
  namespace :bundle do
    desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
    task :app => ["rawr:jar"] do
      require 'app_bundler'
      Rawr::AppBundler.new.deploy RAWR_OPTS
    end

    desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
    task :exe => ["rawr:jar"] do
      require 'exe_bundler'
      Rawr::ExeBundler.new.deploy RAWR_OPTS
    end
  end

  namespace :get do
    desc "Fetch the most recent stable jruby-complete.jar"
    task 'current-stable-jruby' do
      require 'jruby_release'
      #TODO: jruby-complete location should be formally recognized by config
      Rawr::JRubyRelease.get 'stable', 'lib/java'
    end

    desc "Fetch the most recent build of  jruby-complete.jar. Might be an RC"
    task 'current-jruby' do
      require 'jruby_release'
      #TODO: jruby-complete location should be formally recognized by config
      Rawr::JRubyRelease.get 'current', 'lib/java'
    end
  end
end
