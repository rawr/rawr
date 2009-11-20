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

# FIXME: move to a separate class
OUTPUT_FILES = OpenStruct.new
OUTPUT_FILES.compile_dir = RAWR_OPTS.compile_dir
OUTPUT_FILES.meta_inf_dir = File.join(OUTPUT_FILES.compile_dir, "META-INF")
OUTPUT_FILES.jar_output_dir = RAWR_OPTS.jar_output_dir
OUTPUT_FILES.base_jar_filename = RAWR_OPTS.project_name + ".jar"
OUTPUT_FILES.base_jar_complete_path = File.join(OUTPUT_FILES.jar_output_dir,
                                                OUTPUT_FILES.base_jar_filename)
OUTPUT_FILES.java_source_files =
  RAWR_OPTS.source_dirs.inject([]) do |list, directory|
    all_java_files = Dir.glob(File.join(directory, '**', '*.java')).reject{|file| File.directory?(file)}
    relative_filenames = all_java_files.map {|file| directory ? file.sub(File.join(directory, ''), '') : file}
    non_excluded_filenames = relative_filenames.reject {|file|
      RAWR_OPTS.source_exclude_filter.any? {|filter| file =~ filter}
    }
    file_list = non_excluded_filenames.map {|file| OpenStruct.new(:file => file, :directory => directory)}
    list + file_list
  end

namespace :rawr do
  
  desc "Build all data jars"
  task :build_data_jars => [ OUTPUT_FILES.jar_output_dir, "rawr:prepare" ] do
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
    FileUtils.mkdir_p RAWR_OPTS.windows_output_dir
    FileUtils.mkdir_p RAWR_OPTS.osx_output_dir
    FileUtils.mkdir_p RAWR_OPTS.linux_output_dir
  end
  
  directory OUTPUT_FILES.compile_dir
  
  directory OUTPUT_FILES.meta_inf_dir
  
  directory OUTPUT_FILES.jar_output_dir
  
  COMPILED_JAVA_CLASSES = FileList.new
  java_source_file_list = OUTPUT_FILES.java_source_files
  java_source_file_list.each { |file_info|
    delimiter = Platform.instance.argument_delimiter
    file_name = file_info.file
    directory = file_info.directory
    target_file = file_name.pathmap(File.join(OUTPUT_FILES.compile_dir, '%X.class'))
    source_file = File.join(directory, file_name)
    COMPILED_JAVA_CLASSES.add(target_file)
    
    target_jvm_version = [ '-target', RAWR_OPTS.target_jvm_version.to_s ]
    classpath = ['-cp', (RAWR_OPTS.classpath + RAWR_OPTS.source_dirs).join(delimiter) ]
    sourcepath = [ '-sourcepath', RAWR_OPTS.source_dirs.join(delimiter) ]
    outdir = [ '-d', OUTPUT_FILES.compile_dir ]
    base_javac_args = target_jvm_version + classpath + sourcepath + outdir
    
    file target_file => [ source_file, OUTPUT_FILES.compile_dir ] do
      sh 'javac', *(base_javac_args + [source_file])
    end
  }
  
  desc 'Compiles all the Java source and Ruby source files in the source_dirs entry in the build_configuration.rb file.'
  task :compile => COMPILED_JAVA_CLASSES
  task :compile => 'rawr:compile_ruby_classes'
  task :compile => 'rawr:copy_other_file_in_source_dirs'
  
  desc "Compiles the Java source files specified in the source_dirs entry"
  task :compile_java_classes => COMPILED_JAVA_CLASSES
  
  desc "Compiles the Ruby source files specified in the source_dirs entry"
  task :compile_ruby_classes => [ OUTPUT_FILES.compile_dir ] do
    require 'command'
    Rawr::Command.compile_ruby_dirs(RAWR_OPTS.source_dirs,
                                    OUTPUT_FILES.compile_dir,
                                    RAWR_OPTS.jruby_jar,
                                    RAWR_OPTS.source_exclude_filter,
                                    RAWR_OPTS.target_jvm_version,
                                    !RAWR_OPTS.compile_ruby_files)
  end

  desc "Compiles the Duby source files specified in the source_dirs entry"
  task :compile_duby_classes => [ OUTPUT_FILES.compile_dir ] do
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
      target_file = "#{OUTPUT_FILES.compile_dir}/#{processed_file}"

      if file_is_newer?("#{directory}/#{file}", target_file)
        FileUtils.mkdir_p(File.dirname("#{OUTPUT_FILES.compile_dir}/#{processed_file}"))

        sh "dubyc -J-classpath #{directory}/#{file}"
        File.move("#{directory}/#{processed_file}", "#{OUTPUT_FILES.compile_dir}/#{processed_file}")
      end
    end
  end

  task :copy_other_file_in_source_dirs => [ OUTPUT_FILES.compile_dir ] do
    non_source_file_list = RAWR_OPTS.source_dirs.inject([]) do |list, directory|
      all_entries = Dir.glob("#{directory}/**/*")
      all_files = all_entries.reject {|filename| File.directory?(filename)}.
                              reject {|filename| filename =~ /\.(rb|java|class)$/}
      relative_filenames = all_files.map {|filename| directory ? filename.sub("#{directory}/", '') : filename}
      non_excluded_filenames = relative_filenames.reject {|file|
        RAWR_OPTS.source_exclude_filter.inject(false) {|rejected, filter|
          (file =~ filter) || rejected
        }
      }
      file_list = non_excluded_filenames.map {|file| OpenStruct.new(:file => file, :directory => directory)}
      list + file_list
    end
    
    non_source_file_list.each do |data|
      orig_file_path = File.join(data.directory, data.file)
      dest_file_path = File.join(OUTPUT_FILES.compile_dir, data.file)
      puts "Copying non-source file #{orig_file_path} to #{dest_file_path}"
      FileUtils.mkdir_p(File.dirname(dest_file_path))
      if file_is_newer?(orig_file_path, dest_file_path)
        File.copy(orig_file_path, dest_file_path)
      end
    end
  end
  
  file OUTPUT_FILES.base_jar_complete_path => "rawr:compile"
  file OUTPUT_FILES.base_jar_complete_path => OUTPUT_FILES.meta_inf_dir
  file OUTPUT_FILES.base_jar_complete_path => OUTPUT_FILES.jar_output_dir do
    Rawr::Generator.create_manifest_file(RAWR_OPTS)
    Rawr::Generator.create_run_config_file(RAWR_OPTS)
    archive_name = OUTPUT_FILES.base_jar_filename
    Rawr::JarBuilder.new(archive_name, :directory => OUTPUT_FILES.compile_dir).build
    
    # Re-add the manifest file using the jar utility so that it
    # is processed as a manifest file and thus signing will work.
    jar_path = OUTPUT_FILES.base_jar_complete_path
    jar_path = File.join(RAWR_OPTS.jar_output_dir, archive_name)
    manifest_path = File.join(OUTPUT_FILES.compile_dir, 'META-INF', 'MANIFEST.MF')
    sh 'jar', 'ufm', jar_path, manifest_path
  end
  
  desc "Create a base jar file"
  task :base_jar => OUTPUT_FILES.base_jar_complete_path
  
  desc "Uses compiled output and creates an executable jar file."
  task :jar => [ OUTPUT_FILES.base_jar_complete_path, "rawr:build_data_jars" ] do
    (RAWR_OPTS.classpath + RAWR_OPTS.files_to_copy).each do |file|
      destination_file = file.gsub('../', '')
      destination_file_path = File.join(RAWR_OPTS.jar_output_dir, destination_file)
      FileUtils.mkdir_p(File.dirname(destination_file_path))
      File.copy(file, destination_file_path)
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
