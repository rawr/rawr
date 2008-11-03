$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'fileutils'
require 'options'
#require 'rawr_bundle'
require 'rbconfig'
require 'platform'
require 'generator'
require 'jar_builder'

namespace("rawr") do

  desc "Loads data from the build_configuration.rb file. You can override the file to be used by setting RAWR_CONFIG_FILE"
  task :load_configuration do
    Rawr::Options.load_configuration
  end
  
  desc "Build all data jars"
  task :build_data_jars => :prepare do
    Rawr::Options.data.jars_to_build.each do |jar_builder|
      jar_builder.build
    end
  end
  
  desc "Removes generated content"
  task :clean => "rawr:load_configuration" do
    FileUtils.remove_dir(Rawr::Options.data.output_dir) if File.directory? Rawr::Options.data.output_dir
  end

  desc "Creates the output directory and sub-directories, reads in configuration data"
  task :prepare => "rawr:load_configuration" do
    FileUtils.mkdir_p Rawr::Options.data.output_dir
    FileUtils.mkdir_p Rawr::Options.data.compile_dir
    FileUtils.mkdir_p Rawr::Options.data.jar_output_dir
    FileUtils.mkdir_p Rawr::Options.data.windows_output_dir
    FileUtils.mkdir_p Rawr::Options.data.osx_output_dir
    FileUtils.mkdir_p Rawr::Options.data.linux_output_dir
  end

  desc "Compiles all the Java source and Ruby source files in the source_dirs entry in the build_configuration.rb file."
  task :compile => ["rawr:compile_java_classes", "rawr:compile_ruby_classes"]
  
  desc "Compiles the Java source files specified in the source_dirs entry"
  task :compile_java_classes => "rawr:prepare" do
    delimiter = Platform.instance.argument_delimiter
    
    java_source_file_list = Rawr::Options.data.source_dirs.inject([]) do |list, directory|
      list << Dir.glob("#{directory}/**/*.java").
        reject{|file| File.directory?(file)}.
        map!{|file| directory ? file.sub("#{directory}/", '') : file}.
        reject{|file| file =~ Rawr::Options.data.source_exclude_filter}.
        map!{|file| OpenStruct.new(:file => file, :directory => directory)}
    end.flatten!
    
    unless java_source_file_list.empty?
      FileUtils.mkdir_p("#{Rawr::Options.data.compile_dir}/META-INF")

      java_source_file_list.each do |data|
        file = data.file
        directory = data.directory
        target_file = "#{Rawr::Options.data.compile_dir}/#{file.sub(/\.java$/, '.class')}"

        if !File.exists?(target_file) || (File.mtime(target_file) < File.mtime("#{directory}/#{file}"))
          sh "javac -target #{Rawr::Options.data.target_jvm_version} -cp \"#{Rawr::Options.data.classpath.join(delimiter)}\" -sourcepath \"#{Rawr::Options.data.source_dirs.join(delimiter)}\" -d \"#{Rawr::Options.data.compile_dir}\" \"#{directory}/#{file}\""
        end
      end
    end
  end
  
  desc "Compiles the Ruby source files specified in the source_dirs entry"
  task :compile_ruby_classes => "rawr:prepare" do
    ruby_source_file_list = Rawr::Options.data.source_dirs.inject([]) do |list, directory|
      list << Dir.glob("#{directory}/**/*.rb").
            reject{|file| File.directory?(file)}.
            map!{|file| directory ? file.sub("#{directory}/", '') : file}.
            reject{|file| file =~ Rawr::Options.data.source_exclude_filter}.
            map!{|file| OpenStruct.new(:file => file, :directory => directory)}
    end.flatten!

    ruby_source_file_list.each do |data|
      file = data.file
      directory = data.directory
      
      if Rawr::Options.data.compile_ruby_files
        relative_dir, name = File.split(file)
        
        if name[0..0] =~ /\d/
          processed_file = relative_dir + '/$' + name
        else
          processed_file = file
        end
        
        processed_file = processed_file.sub(/\.rb$/, '.class')
        target_file = "#{Rawr::Options.data.compile_dir}/#{processed_file}"
      else
        processed_file = file
        target_file = "#{Rawr::Options.data.compile_dir}/#{file}"
      end

      if !File.exists?(target_file) || (File.mtime(target_file) < File.mtime("#{directory}/#{file}"))
        FileUtils.mkdir_p(File.dirname("#{Rawr::Options.data.compile_dir}/#{processed_file}"))
        
        if Rawr::Options.data.compile_ruby_files
          # There's no jrubyc.bat/com/etc for Windows. jruby -S works universally here
          sh "jruby -S jrubyc #{directory}/#{file}"
          File.move("#{directory}/#{processed_file}", "#{Rawr::Options.data.compile_dir}/#{processed_file}")
        else
          File.copy("#{directory}/#{processed_file}", "#{Rawr::Options.data.compile_dir}/#{processed_file}")
        end
      end
    end
  end

  desc "Uses compiled output and creates an executable jar file."
  task :jar => ["rawr:compile", "rawr:build_data_jars"] do
    Rawr::Generator.create_manifest_file Rawr::Options.data
    Rawr::Generator.create_run_config_file(Rawr::Options.data)
    Rawr::JarBuilder.new("#{Rawr::Options.data.project_name}.jar", :directory => Rawr::Options.data.compile_dir).build

    (Rawr::Options.data.classpath + Rawr::Options.data.files_to_copy).each do |file|
      FileUtils.mkdir_p(File.dirname("#{Rawr::Options.data.jar_output_dir}/#{file}"))
      File.copy(file, "#{Rawr::Options.data.jar_output_dir}/#{file}")
    end
  end
  
  namespace :"bundle" do
    desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
    task :app => [:"rawr:jar"] do
      require 'app_bundler'
      Rawr::AppBundler.new.deploy Rawr::Options.data
    end

    desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
    task :exe => [:"rawr:jar"] do
      require 'exe_bundler'
      Rawr::ExeBundler.new.deploy Rawr::Options.data
    end

#    desc "Bundles the jar from rawr:jar into a Java Web Start application (.jnlp)"
#    task :web => [:"rawr:jar"] do
#      require 'web_bundler'
#      Rawr::WebBundler.new.deploy Rawr::Options.instance
#    end
  end
#
#  desc "Create a keystore"
#  task :keytool => [:setup_consts] do 
#    begin
#      require 'pty'
#    rescue Exception
#      warn "Exception requiring 'pty': #{$!.inspect}"
#      warn "If you are using JRuby, you may need MRI to run the rawr:keytool task"
#      exit
#    end
#
#    keytool( Rawr::Options[:keytool_responses] )
#  end
#
#  # Helper code for ad-hoc 'expect', better than 'rexpect'
#
#  class IO
#    def getline
#      line = ""
#      begin timeout(2) do
#        while ((char = self.getc) != "\n")
#          line << char
#        end
#        line << char
#        return line
#      end
#      rescue Timeout::Error
#        return line
#      end
#    end
#  end
#
#  def keytool(keytool_responses)
#    qna = {
#      /Enter keystore password/  =>  keytool_responses[:password], 
#      /Re-enter new password/ =>   keytool_responses[:password] ,
#      /What is your first and last name?/ =>   keytool_responses[:first_and_last_name],
#      /What is the name of your organization?/ =>  keytool_responses[:organization],
#      /What is the name of your City or Locality/ =>  keytool_responses[:locality],
#      /What is the name of your State or Province?/ =>  keytool_responses[:state_or_province],
#      /What is the two-letter country code for this unit/ =>  keytool_responses[:country_code],
#      /correct/ =>  "yes", 
#      /Enter key password for <myself>/ => keytool_responses[:password], 
#      /Re-enter new password/ => keytool_responses[:password]
#    }
#
#    STDIN.sync = true
#    STDOUT.sync = true
#    STDERR.sync = true
#
#    ENV['TERM'] = "";
#    cmd ='keytool -genkey -keystore sample-keys -alias myself  2>&1'
#    warn `rm sample-keys`
#
#    puts " -- #{cmd} -- "
#    PTY.spawn(cmd) do |r,w,cid| 
#      begin
#        while line = r.getline
#          puts line unless line == ""
#          qna.each do |q,a|
#            if line.match(q)
#              w.puts(a)
#            end
#          end
#        end
#      rescue Exception => e
#        warn "Error running keytool: #{e.inspect}"
#      end
#    end
#  end
end
