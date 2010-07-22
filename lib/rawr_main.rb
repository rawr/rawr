require 'jruby_release'

module Rawr
  class Main

    # Is there anything the user *must* provide for config state?
    REQUIRED_VALUES_ERROR_MSGS = {
      #:project_name => "Missing project name.",
      #:base_package => "Missing base package name.",
      #:target =>  "Missing target."
    }


    REQUIRED_VALUES_EXCLUSIONS = [ ]

    def self.errors
      @@errors ||= []
    end

    def self.valid_options?  options_hash
      @@errors = []
      options_hash.keys.each do |k|
        return true if REQUIRED_VALUES_EXCLUSIONS.include?(k)   
      end

      REQUIRED_VALUES_ERROR_MSGS.each do |val, msg|
        @@errors << msg unless options_hash[val]
      end

      @@errors.empty? 
    end


    def self.project options_hash
      @@current_options = options_hash

      warn  "No ::Rawr::JRubyRelease" unless defined? ::Rawr::JRubyRelease
      warn  "No JRubyRelease" unless defined? JRubyRelease

      puts "HAVE @@current_options = \n#{@@current_options.pretty_inspect}"
      command = @@current_options[:command].shift

      # Might have additonal args in @@current_options[:command]

      case command
      when 'install'
        warn "RUNNING INSTALL with additional args #{@@current_options[:command].inspect}"
        handle_install 
      else
        warn "'#{command}' is not a defined command. "
      end
    end

    def self.handle_install 

      install_dir = '.'
      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      java_class = @@current_options[:class].split(".")
      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      raise "No main java class was defined." if java_class.empty?
      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      directory = @@current_options[:directory]
      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      raise "No directory name for the main Java class was given." if directory.nil? || directory.to_s.strip.empty?
      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG

      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      config_file = @@current_options[:build_config_file]
      raise "No Rawr configuration file name was given." if config_file.nil? || config_file.to_s.strip.empty?
      write_config_file = @@current_options[:no_config]
      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      download_jruby = ! @@current_options[:no_download]
      install_dir = @@current_options[:command].join(' ') unless @@current_options[:command].empty?
      STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG

      FileUtils.mkdir_p install_dir unless install_dir == '.'
      FileUtils.cd install_dir do
        STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
        if write_config_file
          puts "write config file"
          STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
          if File.exist? config_file
            puts "Configuration file '#{config_file}' exists, skipping"
          else
            puts "Creating Rawr configuration file #{config_file}"
            ::Rawr::Creator.create_default_config_file(config_file, java_class.join("."))
          end
        end

        resolved_package = java_class[0...-1].join(".")
        resolved_dir = File.expand_path("#{directory}/#{java_class[0...-1].join('/')}")
        resolved_file = "#{resolved_dir}/#{java_class.last}.java"
        if File.exist? resolved_file
          puts "Java class '#{resolved_file}' exists, skipping"
        else
          puts "Creating Java class #{resolved_file}"
          FileUtils.mkdir_p(resolved_dir)
          ::Rawr::Creator.create_java_main_file(resolved_file, resolved_package, java_class.last)
        end

        create_rakefile

        if download_jruby
          require 'jruby_release'
          puts "Downloading jruby-complete.jar. This may take a moment..."
          require 'jruby_release'
          ::Rawr::JRubyRelease.get 'stable', 'lib/java'
        else
          puts "Check if we need to copy over a local version of jruby-complete.jar ..."
          warn "FIXME!"
        end
      end

    end
  end
end
