$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

module Rawr; end

require 'fileutils'
require 'options'
require 'rawr_bundle'
require 'rbconfig'
require 'platform'
require 'generator'
require 'timeout'


namespace("rawr") do
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
    jar_command = "jar cfM \"#{Rawr::Options[:package_dir]}/#{Rawr::Options[:project_name]}.jar\" -C \"#{Rawr::Options[:package_dir]}\" run_configuration -C \"#{Rawr::Options[:ruby_source_dir][0...Rawr::Options[:ruby_source_dir].index(Rawr::Options[:ruby_source])-1]}\" \"#{Rawr::Options[:ruby_source]}\" -C \"#{Rawr::Options[:ruby_library_dir][0...Rawr::Options[:ruby_library_dir].index(Rawr::Options[:ruby_library])-1]}\" \"#{Rawr::Options[:ruby_library]}\" -C \"#{Rawr::Options[:build_dir]}\" ."
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
