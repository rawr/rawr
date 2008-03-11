require 'fileutils'
require 'yaml'
require 'rawr_bundle'


namespace("rawr") do
  desc "Sets up the various constants used by the Rawr built tasks. These constants come from the build_configuration.yaml file. You can override the file to be used by setting RAWR_CONFIG_FILE"
  task :setup_consts do
    RAWR_CONFIG_FILE = 'build_configuration.yaml' unless Object.const_defined? "RAWR_CONFIG_FILE"
    begin
      @config = YAML.load(File.new(RAWR_CONFIG_FILE))
    rescue Errno::ENOENT
      @config = {}
    end

    PROJECT_NAME = @config['project_name'] || "JRuby project"
    BASE_DIR = Dir::pwd

    JAVA_SOURCE_DIR = "#{BASE_DIR}/#{@config['java_source_dir']}" || "#{BASE_DIR}/src"
    RUBY_SOURCE_DIR = "#{BASE_DIR}/#{@config['ruby_source_dir']}" || "#{BASE_DIR}/src"
    RUBY_SOURCE = @config['ruby_source_dir'] || "src"

    OUTPUT_DIR = "#{BASE_DIR}/#{@config['output_dir']}" || "#{BASE_DIR}/package"
    BUILD_DIR = "#{OUTPUT_DIR}/bin"
    PACKAGE_DIR = "#{OUTPUT_DIR}/deploy"

    CLASSPATH_DIRS = (@config['classpath_dirs'] || []).map {|e| "#{BASE_DIR}/#{e}"}
    CLASSPATH_FILES = @config['classpath_files'] || []
    NATIVE_LIBRARY_DIRS = (@config['native_library_dirs'] || []).map {|e| "#{BASE_DIR}/#{e}"}
    CLASSPATH = (CLASSPATH_DIRS.map{|cp| Dir.glob("#{cp}**/*.jar")} + CLASSPATH_FILES + ["#{PROJECT_NAME}.jar"]).flatten

    MAIN_RUBY_FILE = @config['main_ruby_file'] || "main"
    MAIN_JAVA_FILE = @config['main_java_file'] || "org.rubyforge.rawr.Main"
    JAR_DATA_DIRS = @config['jar_data_dirs'] || []
    PACKAGE_DATA_DIRS = @config['package_data_dirs'] || []
  end

  desc "Removes the output directory"
  task :clean => "rawr:setup_consts" do
    FileUtils.remove_dir(OUTPUT_DIR) if File.directory? OUTPUT_DIR
  end

  desc "Creates the output directory and sub-directories, reads in configuration data"
  task :prepare => "rawr:setup_consts" do
    Dir.mkdir(OUTPUT_DIR) unless File.directory?(OUTPUT_DIR)
    Dir.mkdir(BUILD_DIR) unless File.directory?(BUILD_DIR)
    Dir.mkdir(PACKAGE_DIR) unless File.directory?(PACKAGE_DIR)
  end

  desc "Compiles all the Java source files in the directory declared in the build_configuration.yaml file. Also generates a manifest file for use in a jar file"
  task :compile => "rawr:prepare" do
    delimiter = RUBY_PLATFORM =~ /mswin/ ? ';' : ':'
    Dir.mkdir(BUILD_DIR + "/META-INF") unless File.directory?(BUILD_DIR + "/META-INF")
    Dir.glob("#{JAVA_SOURCE_DIR}/**/*.java").each do |file|
      sh "javac -cp \"#{CLASSPATH.join(delimiter)}\" -sourcepath #{JAVA_SOURCE_DIR} -d #{BUILD_DIR} #{file}"
      f = File.new("#{BUILD_DIR}/META-INF/MANIFEST.MF", "w+")
      f << "Manifest-Version: 1.0\n"
      f << "Class-Path: " << CLASSPATH.map{|file| file.gsub(BASE_DIR + '/', '')}.join(" ") << " . \n"
      f << "Main-Class: #{MAIN_JAVA_FILE}\n"
      f.close
    end
  end

  desc "Uses compiled output and creates an executable jar file."
  task :jar => "rawr:compile" do
    run_configuration = File.new("#{PACKAGE_DIR}/run_configuration", "w+")
    run_configuration << "ruby_source_dir: " + RUBY_SOURCE + "\n"
    run_configuration << "main_ruby_file: " + MAIN_RUBY_FILE + "\n"
    run_configuration << "native_library_dirs: " + NATIVE_LIBRARY_DIRS.map{|dir| dir.gsub(BASE_DIR + '/', '')}.join(" ")
    run_configuration.close
    
    #add in any data directories into the jar
    jar_command = "jar cfM #{PACKAGE_DIR}/#{PROJECT_NAME}.jar -C #{PACKAGE_DIR}  run_configuration -C #{RUBY_SOURCE_DIR[0...RUBY_SOURCE_DIR.index(RUBY_SOURCE)-1]} #{RUBY_SOURCE} -C #{BUILD_DIR} ."
    JAR_DATA_DIRS.each do |dir|
      parts = dir.split("/")
      if 1 == parts.size
        jar_command << " -C #{BASE_DIR} #{parts[0]}"
      else
        jar_command << " -C #{parts[0...-1].join("/")} #{parts[-1]}"      
      end
    end
    sh jar_command
    # File.delete("#{PACKAGE_DIR}/run_configuration")
    ((CLASSPATH_DIRS + NATIVE_LIBRARY_DIRS + PACKAGE_DATA_DIRS).flatten.map {|cp| Dir.glob("#{cp}/**/*").reject{|e| e =~ /\.svn/}.map{|file| file.gsub(BASE_DIR + '/', '')}} + CLASSPATH_FILES).flatten.uniq.each do |file|
       FileUtils.mkdir_p("#{PACKAGE_DIR}/#{File.dirname(file).gsub(BASE_DIR + '/', '')}")
       FileUtils.copy(file, "#{PACKAGE_DIR}/#{file.gsub(BASE_DIR + '/', '')}") unless File.directory?(file)
    end
  end
end
