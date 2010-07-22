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
 STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      java_class = @@current_options[:class].split(".")
      raise "No main java class was defined." if java_class.empty?
      directory = @@current_options[:directory]
 STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      raise "No directory name for the main Java class was given." if directory.nil? || directory.to_s.strip.empty?

      config_file = @@current_options[:build_config_file]
 STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      raise "No Rawr configuration file name was given." if config_file.nil? || config_file.to_s.strip.empty?
      write_config_file = @@current_options[:no_config]
 STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG
      download_jruby = !(@@current_options[:no_download] || @@current_options[:no_jar] )
      install_dir = @@current_options[:command].empty? ? '.' : @@current_options[:command].join(' ') 
 STDERR.puts( ":DEBUG #{__FILE__}:#{__LINE__}" ) if ENV['JAMES_SCA_JDEV_MACHINE'] # JGBDEBUG

      FileUtils.mkdir_p install_dir unless install_dir == '.'

      FileUtils.cd install_dir do

        if write_config_file
          puts "write config file"
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
          unless @@current_options[:no_jar] 
            if @@current_options[:local_jruby_jar].to_s.strip.empty?
              warn "The rawr configuration indicates copying over a local jruby-complete.jar, but there is no file path defined for this."
              warn "Your 'install' configuration is:\n#{@@current_options.pretty_inspect}"
            else
              copy_to = File.expand_path "#{install_dir}/lib/java"
              FileUtils.mkdir_p copy_to
              if File.exist? "#{copy_to}/jruby-complete.jar
                warn "#{copy_to}/jruby-complete.jar already exists.  Not copying."
              else
                File.cp @@current_options[:local_jruby_jar], copy_to
              end
            end # @@current_options[:local_jruby_jar].to_s.strip.empty?
          else 
            puts "Based on the given configuration, no jruby-complete.jar file will be added to the project."
          end  # @@current_options[:no_jar] 
        end # if download_jruby
      end # install_dr do
    end
  end
end
