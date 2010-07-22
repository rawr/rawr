require 'jruby_release'

module Rawr
  class Main

    @@wordy = false

    def self.errors
      @@errors ||= []
    end

    def self.valid_options?  options_hash
      @@errors = []

      if options_hash[:command].nil? || options_hash[:command].empty?
        @@errors << "You must pass a command.  Right now, the only one you can use is 'install'."
      end


      @@errors.empty? 
    end

    def self.show_version current_options
      puts "rawr version #{::Rawr::VERSION}"
      w "Your configuration settings are:\n#{current_options.pretty_inspect}"
    end

    def self.w msg
       puts(msg) if @@wordy
    end

    def self.project current_options
      command = current_options[:command].shift
      @@wordy = current_options[:wordy]

      # Might have additonal args in current_options[:command]

      # First handle some psuedo commands
      if current_options[:show_version] 
        show_version current_options
        exit
      end

      case command
      when 'install'
        handle_install current_options
      else
        warn "'#{command}' is not a defined command. "
        w "Your configuration values are:\n#{current_options.pretty_inspect}"
      end
    end

    def self.handle_install current_options
      w "Running 'install' with options\n#{current_options.pretty_inspect}"
      java_class = current_options[:class].split(".")
      raise "No main java class was defined." if java_class.empty?

      directory = current_options[:directory]
      raise "No directory name for the main Java class was given." if directory.nil? || directory.to_s.strip.empty?

      config_file = current_options[:build_config_file]
      raise "No Rawr configuration file name was given." if config_file.nil? || config_file.to_s.strip.empty?

      write_config_file = !current_options[:no_config]
      w "The choice to create a config file  is #{write_config_file}, based on the :no_config value #{current_options[:no_config].inspect}"

      download_jruby = !(current_options[:no_download] || current_options[:no_jar] )

      w "The choice to download a JRuby jar is #{download_jruby}, as determined by :no_download = #{current_options[:no_download].inspect} and   :no_jar = #{current_options[:no_jar].inspect}"

      install_dir = current_options[:command].empty? ? '.' : current_options[:command].join(' ') 
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
        else
          warn "No configuration file will be created because of your rawr settings"
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
          unless current_options[:no_jar] 
            if current_options[:local_jruby_jar].to_s.strip.empty?
              warn "The rawr configuration indicates copying over a local jruby-complete.jar, but there is no file path defined for this."
              w "Your 'install' configuration is:\n#{current_options.pretty_inspect}"
            else
              copy_to = File.expand_path "#{install_dir}/lib/java"
              FileUtils.mkdir_p copy_to
              if File.exist? "#{copy_to}/jruby-complete.jar"
                warn "#{copy_to}/jruby-complete.jar already exists.  Not copying."
              else
                puts "Copying #{current_options[:local_jruby_jar]} to #{copy_to} ..."
                FileUtils.cp current_options[:local_jruby_jar], copy_to
              end
            end # current_options[:local_jruby_jar].to_s.strip.empty?
          else 
            puts "Based on the given configuration, no jruby-complete.jar file will be added to the project."
          end  # current_options[:no_jar] 
        end # if download_jruby
      end # install_dr do
      puts "All done! "
    end
  end
end
