$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

module Rawr; end

require 'fileutils'
require 'options'
require 'rawr_bundle'
require 'rbconfig'
require 'platform'
require 'generator'
require 'timeout'


def ruby_lib_parent_dir
  return nil unless Rawr::Options[:ruby_library]
  begin
    "#{Rawr::Options[:ruby_library_dir][0...Rawr::Options[:ruby_library_dir].index(Rawr::Options[:ruby_library])-1]}"
  rescue Exception => e
    raise "There was a problem deterining your Ruby lib directory.\n\nPlease check your build_configuration.yaml file and your directory structure."
  end
end

def ruby_source_parent_dir
  begin
    "#{Rawr::Options[:ruby_source_dir][0...Rawr::Options[:ruby_source_dir].index(Rawr::Options[:ruby_source])-1]}"
  rescue Exception => e
    raise "There was a problem deterining your Ruby source directory.\n\nPlease check your build_configuration.yaml file and your directory structure."
  end
end

def jar_command_for_ruby_src_dir
  return ' ' unless ruby_source_parent_dir 
  " -C \"#{ruby_source_parent_dir}\"  \"#{Rawr::Options[:ruby_source]}\" " 
end


def jar_command_for_ruby_lib_dir
  return ' ' unless ruby_lib_parent_dir
  " -C \"#{ruby_lib_parent_dir}\" \"#{Rawr::Options[:ruby_library]}\"  " 
end

def build_configuration
  @build_configuration ||= YAML.load(IO.read('build_configuration.yaml'))
end

def ruby_src_dir
  build_configuration['ruby_source_dir']
end

def ruby_lib_dir
  build_configuration['ruby_library_dir']
end


def jar_file_name
  "#{build_configuration['output_dir']}/deploy/#{build_configuration['project_name']}.jar"
end


def rb_to_class(src_file_path)
  if File.exist? src_file_path
    c_name = src_file_path.sub( '.rb', '.class')
    sh "rm #{c_name}" if File.exist?(c_name)
    sh "jrubyc  #{src_file_path}"
  end
end

def dir_rb_to_class(dir_name, suffix = '_real')
  Find.find(dir_name) do |f|
    if f =~ /\.rb$/
      rb_to_class f
    end
  end
end

def clean_jar(jar_path)
  begin
    require 'zip/zip' # Need rubyzip gem installed for this
  rescue Exception => e
    raise "Exception running 'clean_jar'; you may need to install the 'rubyzip' gem."
  end
  Zip::ZipFile.open(jar_path) do |zf|
    zf.entries.each do |e|
      if e.name =~ /\.(rb|java)$/
        warn "  - Removing #{e}"
        zf.remove(e)
      end
    end
  end

  Zip::ZipFile.open(jar_path) do |zf|
    zf.entries.each do |e|
      if e.name =~ /\.(rb|java)$/
        raise "Failed to remove #{e.name}"
      end
    end
  end
end

namespace("rawr") do

  desc "class-up all rb files under src/ and lib/ruby/"
  task :'class-jar' do
    ruby_dirs = [ ruby_src_dir,  ruby_lib_dir ]
    ruby_dirs.each do |d|
      dir_rb_to_class d
    end
    sh "rake rawr:jar"
    clean_jar jar_file_name
  end

  desc "Sets up the various constants used by the Rawr built tasks. These constants come from the build_configuration.yaml file. You can override the file to be used by setting RAWR_CONFIG_FILE"
  task :setup_consts do
    config_file = 'build_configuration.yaml' unless Object.const_defined? "RAWR_CONFIG_FILE"
    Rawr::Options.load_configuration config_file
  end

  desc "Removes the output directory"
  task :clean => "rawr:setup_consts" do
    FileUtils.remove_dir(Rawr::Options[:output_dir]) if File.directory? Rawr::Options[:output_dir]
  end

  desc "Creates the output directory and sub-directories, reads in configuration data"
  task :prepare => "rawr:setup_consts" do
    FileUtils.mkdir_p Rawr::Options[:output_dir]
    FileUtils.mkdir_p Rawr::Options[:build_dir]
    FileUtils.mkdir_p Rawr::Options[:package_dir]
  end

  desc "Compiles all the Java source files in the directory declared in the build_configuration.yaml file. Also generates a manifest file for use in a jar file"
  task :compile => "rawr:prepare" do
    FileUtils.mkdir_p(Rawr::Options[:build_dir] + "/META-INF")
    Dir.glob("#{Rawr::Options[:java_source_dir]}/**/*.java").each do |file|
      delimiter = Platform.instance.argument_delimiter
      sh "javac -cp \"#{Rawr::Options[:classpath].join(delimiter)}\" -sourcepath \"#{Rawr::Options[:java_source_dir]}\" -d \"#{Rawr::Options[:build_dir]}\" \"#{file}\""
      Rawr::Generator.create_manifest_file Rawr::Options
    end
  end

  desc "Uses compiled output and creates an executable jar file."
  task :jar => "rawr:compile" do
    Rawr::Generator.create_run_config_file(Rawr::Options)

    #add in any data directories into the jar
    jar_command = "jar cfM \"#{Rawr::Options[:package_dir]}/#{Rawr::Options[:project_name]}.jar\" " +  
                  " -C \"#{Rawr::Options[:package_dir]}\" run_configuration " + # " -C \"#{ruby_source_parent_dir}\"  \"#{Rawr::Options[:ruby_source]}\" " + 
                  jar_command_for_ruby_src_dir + 
                  jar_command_for_ruby_lib_dir + 
                  " -C \"#{Rawr::Options[:build_dir]}\" ."

    Rawr::Options[:jar_data_dirs].each do |dir|
      parts = dir.split("/")
      if 1 == parts.size
        jar_command << " -C \"#{Rawr::Options[:base_dir]}\" \"#{parts[0]}\""
      else
        jar_command << " -C \"#{parts[0...-1].join("/")}\" \"#{parts[-1]}\""
      end
    end

    sh jar_command

    File.delete("#{Rawr::Options[:package_dir]}/run_configuration")
    ((Rawr::Options[:classpath_dirs] + Rawr::Options[:package_data_dirs]).flatten.map {|cp| Dir.glob("#{cp}/**/*").reject{|e| e =~ /\.svn/}.map{|file| file.gsub(Rawr::Options[:base_dir] + '/', '')}} + Rawr::Options[:classpath_files]).flatten.uniq.each do |file|
      FileUtils.mkdir_p("#{Rawr::Options[:package_dir]}/#{File.dirname(file).gsub(Rawr::Options[:base_dir] + '/', '')}")
      FileUtils.copy(file, "#{Rawr::Options[:package_dir]}/#{file.gsub(Rawr::Options[:base_dir] + '/', '')}") unless File.directory?(file)
    end

    Rawr::Options[:native_library_dirs].each do |native_dir| 
      Dir.glob("#{native_dir}/**/*").reject{|e| e =~ /\.svn/}.map{|file| file.gsub(Rawr::Options[:base_dir] + '/', '')}.each do |file|
        FileUtils.copy(file, "#{Rawr::Options[:package_dir]}/#{File.basename(file)}")
      end
    end

    Rawr::Options[:jars].values.each do |jar_builder|
      puts "========================== Packaging #{jar_builder.name} ==============================="
      jar_builder.build
      FileUtils.copy(jar_builder.name, "#{Rawr::Options[:package_dir]}/")
    end
  end



  desc "Create a keystore"
  task :keytool => [:setup_consts] do 
    begin
      require 'pty'
    rescue Exception
      warn "Exception requiring 'pty': #{$!.inspect}"
      warn "If you are using JRuby, you may need MRI to run the rawr:keytool task"
      exit
    end

    keytool( Rawr::Options[:keytool_responses] )
  end

  # Helper code for ad-hoc 'expect', better than 'rexpect'

  class IO
    def getline
      line = ""
      begin timeout(2) do
        while ((char = self.getc) != "\n")
          line << char
        end
        line << char
        return line
      end
      rescue Timeout::Error
        return line
      end
    end
  end

  def keytool(keytool_responses)
    qna = {
      /Enter keystore password/  =>  keytool_responses[:password], 
      /Re-enter new password/ =>   keytool_responses[:password] ,
      /What is your first and last name?/ =>   keytool_responses[:first_and_last_name],
      /What is the name of your organization?/ =>  keytool_responses[:organization],
      /What is the name of your City or Locality/ =>  keytool_responses[:locality],
      /What is the name of your State or Province?/ =>  keytool_responses[:state_or_province],
      /What is the two-letter country code for this unit/ =>  keytool_responses[:country_code],
      /correct/ =>  "yes", 
      /Enter key password for <myself>/ => keytool_responses[:password], 
      /Re-enter new password/ => keytool_responses[:password]
    }

    STDIN.sync = true
    STDOUT.sync = true
    STDERR.sync = true

    ENV['TERM'] = "";
    cmd ='keytool -genkey -keystore sample-keys -alias myself  2>&1'
    warn `rm sample-keys`

    puts " -- #{cmd} -- "
    PTY.spawn(cmd) do |r,w,cid| 
      begin
        while line = r.getline
          puts line unless line == ""
          qna.each do |q,a|
            if line.match(q)
              w.puts(a)
            end
          end
        end
      rescue Exception
        warn "Error running keytool: #{$!.inspect}"
      end
    end
  end
end
