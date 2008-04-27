$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

module Rawr; end

require 'fileutils'
require 'yaml'
require 'rawr_bundle'
require 'rbconfig'
require 'platform'


namespace("rawr") do
  desc "Sets up the various constants used by the Rawr built tasks. These constants come from the build_configuration.yaml file. You can override the file to be used by setting RAWR_CONFIG_FILE"
  task :setup_consts do
    RAWR_CONFIG_FILE = 'build_configuration.yaml' unless Object.const_defined? "RAWR_CONFIG_FILE"
    begin
      @config = YAML.load(File.new(RAWR_CONFIG_FILE))
    rescue Errno::ENOENT
      @config = {}
    end

    Rawr::PROJECT_NAME = @config['project_name'] || "JRuby project"
    Rawr::BASE_DIR = Dir::pwd

    Rawr::JAVA_SOURCE_DIR = "#{Rawr::BASE_DIR}/#{@config['java_source_dir']}" || "#{Rawr::BASE_DIR}/src"
    Rawr::RUBY_SOURCE_DIR = "#{Rawr::BASE_DIR}/#{@config['ruby_source_dir']}" || "#{Rawr::BASE_DIR}/src"
    Rawr::RUBY_LIBRARY_DIR = "#{Rawr::BASE_DIR}/#{@config['ruby_library_dir']}" || "#{Rawr::BASE_DIR}/lib"
    Rawr::RUBY_SOURCE = @config['ruby_source_dir'] || "src"
    Rawr::RUBY_LIBRARY = @config['ruby_library_dir'] || "lib"

    Rawr::OUTPUT_DIR = "#{Rawr::BASE_DIR}/#{@config['output_dir']}" || "#{Rawr::BASE_DIR}/package"
    Rawr::BUILD_DIR = "#{Rawr::OUTPUT_DIR}/bin"
    Rawr::PACKAGE_DIR = "#{Rawr::OUTPUT_DIR}/deploy"

    Rawr::CLASSPATH_DIRS = (@config['classpath_dirs'] || []).map {|e| "#{Rawr::BASE_DIR}/#{e}"}
    Rawr::CLASSPATH_FILES = @config['classpath_files'] || []
    Rawr::NATIVE_LIBRARY_DIRS = (@config['native_library_dirs'] || []).map {|e| "#{Rawr::BASE_DIR}/#{e}"}
    Rawr::CLASSPATH = (Rawr::CLASSPATH_DIRS.map{|cp| Dir.glob("#{cp}**/*.jar")} + Rawr::CLASSPATH_FILES + ["#{Rawr::PROJECT_NAME}.jar"]).flatten

    Rawr::MAIN_RUBY_FILE = @config['main_ruby_file'] || "main"
    Rawr::MAIN_JAVA_FILE = @config['main_java_file'] || "org.rubyforge.rawr.Main"
    Rawr::JAR_DATA_DIRS = @config['jar_data_dirs'] || []
    Rawr::PACKAGE_DATA_DIRS = @config['package_data_dirs'] || []
  end

  desc "Removes the output directory"
  task :clean => "rawr:setup_consts" do
    FileUtils.remove_dir(Rawr::OUTPUT_DIR) if File.directory? Rawr::OUTPUT_DIR
  end

  desc "Creates the output directory and sub-directories, reads in configuration data"
  task :prepare => "rawr:setup_consts" do
    Dir.mkdir(Rawr::OUTPUT_DIR) unless File.directory?(Rawr::OUTPUT_DIR)
    Dir.mkdir(Rawr::BUILD_DIR) unless File.directory?(Rawr::BUILD_DIR)
    Dir.mkdir(Rawr::PACKAGE_DIR) unless File.directory?(Rawr::PACKAGE_DIR)
  end

  desc "Compiles all the Java source files in the directory declared in the build_configuration.yaml file. Also generates a manifest file for use in a jar file"
  task :compile => "rawr:prepare" do
    
    delimiter = Platform.instance.argument_delimiter
    Dir.mkdir(Rawr::BUILD_DIR + "/META-INF") unless File.directory?(Rawr::BUILD_DIR + "/META-INF")
    Dir.glob("#{Rawr::JAVA_SOURCE_DIR}/**/*.java").each do |file|
      sh "javac -cp \"#{Rawr::CLASSPATH.join(delimiter)}\" -sourcepath \"#{Rawr::JAVA_SOURCE_DIR}\" -d \"#{Rawr::BUILD_DIR}\" \"#{file}\""
      f = File.new("#{Rawr::BUILD_DIR}/META-INF/MANIFEST.MF", "w+")
      f << "Manifest-Version: 1.0\n"
      f << "Class-Path: " << Rawr::CLASSPATH.map{|file| file.gsub(Rawr::BASE_DIR + '/', '')}.join(" ") << " . \n"
      f << "Main-Class: #{Rawr::MAIN_JAVA_FILE}\n"
      f.close
    end
  end

  desc "Uses compiled output and creates an executable jar file."
  task :jar => "rawr:compile" do
    run_configuration = File.new("#{Rawr::PACKAGE_DIR}/run_configuration", "w+")
    run_configuration << "ruby_source_dir: " + Rawr::RUBY_SOURCE + "\n"
    run_configuration << "main_ruby_file: " + Rawr::MAIN_RUBY_FILE + "\n"
    run_configuration << "native_library_dirs: " + Rawr::NATIVE_LIBRARY_DIRS.map{|dir| dir.gsub(Rawr::BASE_DIR + '/', '')}.join(" ")
    run_configuration.close
    
    #add in any data directories into the jar
    jar_command = "jar cfM \"#{Rawr::PACKAGE_DIR}/#{Rawr::PROJECT_NAME}.jar\" -C \"#{Rawr::PACKAGE_DIR}\" run_configuration -C \"#{Rawr::RUBY_SOURCE_DIR[0...Rawr::RUBY_SOURCE_DIR.index(Rawr::RUBY_SOURCE)-1]}\" \"#{Rawr::RUBY_SOURCE}\" -C \"#{Rawr::RUBY_LIBRARY_DIR[0...Rawr::RUBY_LIBRARY_DIR.index(Rawr::RUBY_LIBRARY)-1]}\" \"#{Rawr::RUBY_LIBRARY}\" -C \"#{Rawr::BUILD_DIR}\" ."
    Rawr::JAR_DATA_DIRS.each do |dir|
      parts = dir.split("/")
      if 1 == parts.size
        jar_command << " -C \"#{Rawr::BASE_DIR}\" \"#{parts[0]}\""
      else
        jar_command << " -C \"#{parts[0...-1].join("/")}\" \"#{parts[-1]}\""
      end
    end
    sh jar_command
    # File.delete("#{PACKAGE_DIR}/run_configuration")
    ((Rawr::CLASSPATH_DIRS + Rawr::NATIVE_LIBRARY_DIRS + Rawr::PACKAGE_DATA_DIRS).flatten.map {|cp| Dir.glob("#{cp}/**/*").reject{|e| e =~ /\.svn/}.map{|file| file.gsub(Rawr::BASE_DIR + '/', '')}} + Rawr::CLASSPATH_FILES).flatten.uniq.each do |file|
       FileUtils.mkdir_p("#{Rawr::PACKAGE_DIR}/#{File.dirname(file).gsub(Rawr::BASE_DIR + '/', '')}")
       FileUtils.copy(file, "#{Rawr::PACKAGE_DIR}/#{file.gsub(Rawr::BASE_DIR + '/', '')}") unless File.directory?(file)
    end
  end
end
