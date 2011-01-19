require 'rawr/jruby_release'

class String
  def to_b
    self =~ /true/i ? true : false
  end
end

module Rawr
  class Main

    @@wordy = ENV['RAWR_WORDY']

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
      warn(msg) if @@wordy || ENV['WORDY']
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
      end
    end


    def self.adjust current_options
      current_options.each do |k, v|
        current_options[k] = v.to_b if v =~/true|false/i
      end
    end

    def self.handle_install current_options
      adjust current_options
      
      java_class = current_options[:class].split(".")
      java_class = current_options[:class].split(".")
      java_class = current_options[:class].split(".")

      raise "No main java class was defined." if java_class.empty?
      directory = current_options[:directory]
      raise "No directory name for the main Java class was given." if directory.nil? || directory.to_s.strip.empty?
      config_path = current_options[:build_config_file]
      raise "No Rawr configuration file name was given." if config_path.nil? || config_path.to_s.strip.empty?
      write_config_file = !current_options[:no_config]
      w "The choice to create a config file  is #{write_config_file}, based on the :no_config value #{current_options[:no_config].inspect}"

      download_jruby = !(current_options[:no_download] || current_options[:no_jar] )

      w "The choice to download a JRuby jar is #{download_jruby}, as determined by :no_download = #{current_options[:no_download].inspect} and   :no_jar = #{current_options[:no_jar].inspect}"

      install_dir = current_options[:command].empty? ? Dir.pwd : current_options[:command].join(' ') 
      
      current_options['project_name'] =  if install_dir == '.'
                                               Dir.pwd.split(File::SEPARATOR).last
                                             else
                                               install_dir.split(File::SEPARATOR).last
                                             end
      
      w "install_dir is '#{install_dir}'"
     
     w "current_options['project_name']  = #{current_options['project_name'] 
     }"
      FileUtils.mkdir_p install_dir unless install_dir == '.'

      FileUtils.cd install_dir do

        if write_config_file
          warn "write config file"
          if File.exist? config_path
            warn "Configuration file '#{config_path}' exists, skipping"
          else
            warn "Creating Rawr configuration file #{config_path}"
            ::Rawr::Creator.create_default_config_file(config_path, java_class.join("."), current_options['project_name'])
          end
        else
          warn "No configuration file will be created because of your rawr settings"
        end

        resolved_package = java_class[0...-1].join(".")
        resolved_dir = File.expand_path("#{directory}/#{java_class[0...-1].join('/')}")
        resolved_file = "#{resolved_dir}/#{java_class.last}.java"

        if File.exist? resolved_file
          warn "Java class '#{resolved_file}' exists, skipping"
        else
          warn "Creating Java class #{resolved_file}"
          FileUtils.mkdir_p(resolved_dir)
          ::Rawr::Creator.create_java_main_file(resolved_file, resolved_package, java_class.last)
        end

        create_rakefile

        if download_jruby

          require 'rawr/jruby_release'
          warn "Downloading jruby-complete.jar. This may take a moment..."
          require 'rawr/jruby_release'
          ::Rawr::JRubyRelease.get 'stable', 'lib/java'

        else
          unless current_options[:no_jar] 
            if current_options[:local_jruby_jar].to_s.strip.empty?
              warn "The rawr configuration indicates copying over a local jruby-complete.jar, but there is no file path defined for this."
              warn "Your 'install' configuration is:\n#{current_options.pretty_inspect}"
            else
              copy_to = File.expand_path "lib/java"
              FileUtils.mkdir_p copy_to
              if File.exist? "#{copy_to}/jruby-complete.jar"
                warn "#{copy_to}/jruby-complete.jar already exists.  Not copying."
              else
                warn "Copying #{current_options[:local_jruby_jar]} to #{copy_to} ..."
                FileUtils.cp current_options[:local_jruby_jar], copy_to
              end
            end # current_options[:local_jruby_jar].to_s.strip.empty?
          else 
            warn "Based on the given configuration, no jruby-complete.jar file will be added to the project."
          end  # current_options[:no_jar] 
        end # if download_jruby
      end # install_dr do
      warn "All done! "
    end
  end
end
