require 'fileutils'

task :setup_consts do
  RAWR_CONFIG_FILE = 'build_configuration.yaml' unless Object.const_defined? "RAWR_CONFIG_FILE"
  @config = YAML.load(File.new(RAWR_CONFIG_FILE))
  PROJECT_NAME = @config['project_name']
  BASE_DIR = Dir::pwd

  JAVA_SOURCE_DIR = "#{BASE_DIR}/#{@config['java_source_dir']}"
  RUBY_SOURCE_DIR = "#{BASE_DIR}/#{@config['ruby_source_dir']}"
  RUBY_SOURCE = @config['ruby_source_dir']

  OUTPUT_DIR = "#{BASE_DIR}/#{@config['output_dir']}"
  BUILD_DIR = "#{OUTPUT_DIR}/bin"
  PACKAGE_DIR = "#{OUTPUT_DIR}/deploy"

  CLASSPATH_DIRS = (@config['classpath_dirs'] || []).map {|e| "#{BASE_DIR}/#{e}"}
  CLASSPATH_FILES = @config['classpath_files']
  NATIVE_LIBRARY_DIRS = @config['native_library_dirs'].map {|e| "#{BASE_DIR}/#{e}"}
  CLASSPATH = (CLASSPATH_DIRS.map{|cp| Dir.glob("#{cp}**/*.jar")} + CLASSPATH_FILES).flatten

  MAIN_RUBY_FILE = @config['main_ruby_file']
  JAR_DATA_DIRS = @config['jar_data_dirs'] || []
  PACKAGE_DATA_DIRS = @config['package_data_dirs'] || []
end

task :clean => :setup_consts do
  FileUtils.remove_dir(OUTPUT_DIR) if File.directory? OUTPUT_DIR
end

task :prepare => :setup_consts do
  Dir.mkdir(OUTPUT_DIR) unless File.directory?(OUTPUT_DIR)
  Dir.mkdir(BUILD_DIR) unless File.directory?(BUILD_DIR)
  Dir.mkdir(PACKAGE_DIR) unless File.directory?(PACKAGE_DIR)
end

task :compile => :prepare do
  delimiter = RUBY_PLATFORM =~ /mswin/ ? ';' : ':'
  Dir.mkdir(BUILD_DIR + "/META-INF") unless File.directory?(BUILD_DIR + "/META-INF")
  Dir.glob("#{JAVA_SOURCE_DIR}/**/*.java").each do |file|
    sh "javac -cp \"#{CLASSPATH.join(delimiter)}\" -sourcepath #{JAVA_SOURCE_DIR} -d #{BUILD_DIR} #{file}"
    f = File.new("#{BUILD_DIR}/META-INF/MANIFEST.MF", "w+")
    f << "Manifest-Version: 1.0\n"
    f << "Class-Path: " << CLASSPATH.map{|file| file.gsub(BASE_DIR + '/', '')}.join(" ") << " . \n"
    f << "Main-Class: org.monkeybars.Main\n"
    f.close
  end
end

task :jar => :compile do
  run_configuration = File.new("#{PACKAGE_DIR}/run_configuration", "w+")
  run_configuration << RUBY_SOURCE + "\n"
  run_configuration << MAIN_RUBY_FILE + "\n"
  run_configuration << NATIVE_LIBRARY_DIRS.map{|dir| dir.gsub(BASE_DIR + '/', '')}.join(" ")
  run_configuration.close
  
  #add in any data directories into the jar
  jar_command = "jar cfM #{PACKAGE_DIR}/#{PROJECT_NAME}.jar -C #{RUBY_SOURCE_DIR[0...RUBY_SOURCE_DIR.index(RUBY_SOURCE)-1]} #{RUBY_SOURCE} -C #{BUILD_DIR} ."
  JAR_DATA_DIRS.each do |dir|
    parts = dir.split("/")
    if 1 == parts.size
      jar_command << " -C #{BASE_DIR} #{parts[0]}"
    else
      jar_command << " -C #{parts[0...-1].join("/")} #{parts[-1]}"      
    end
  end
  sh jar_command

  ((CLASSPATH_DIRS + NATIVE_LIBRARY_DIRS + PACKAGE_DATA_DIRS).flatten.map {|cp| Dir.glob("#{cp}/**/*").reject{|e| e =~ /\.svn/}.map{|file| file.gsub(BASE_DIR + '/', '')}} + CLASSPATH_FILES).flatten.uniq.each do |file|
     FileUtils.mkdir_p("#{PACKAGE_DIR}/#{File.dirname(file).gsub(BASE_DIR + '/', '')}")
     File.copy(file, "#{PACKAGE_DIR}/#{file.gsub(BASE_DIR + '/', '')}") unless File.directory?(file)
  end
end