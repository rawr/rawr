require 'rawr/configuration'
require 'rawr/bundler_template'

module Rawr
  class Creator
    def self.create_run_config_file options
      slash = options.compile_ruby_files ? ' ' : '/'
      File.open(File.join(options.compile_dir, 'run_configuration'), "w+") do |run_config_file|
        run_config_file.puts "load_path_slash:#{slash}"
        run_config_file.puts "main_ruby_file: " + options.main_ruby_file
        run_config_file.puts "source_dirs: " + options.source_dirs.join(';')
      end
    end
    
    def self.create_manifest_file options
      metainf_dir_path = File.join options.compile_dir, 'META-INF'
      manifest_path = File.join metainf_dir_path, 'MANIFEST.MF'
      
      lib_dirs = options.classpath.map {|cp| cp.gsub('../', '')}
      lib_jars = options.jars.keys.map {|key| key.to_s + ".jar"}
      libraries = lib_dirs + lib_jars + ["."]
      
      File.open(manifest_path, "w+") do |manifest_file|
        manifest_file << "Manifest-Version: 1.0\n"
        manifest_file << "Class-Path: " + libraries.join("\n  ") + "\n"
        manifest_file << "Main-Class: " + options.main_java_file + "\n"
      end
    end
    
    def self.create_java_main_file java_file, java_package, java_class
      File.open(java_file, "w+") do |java_main_file|
        java_main_file.puts BundlerTemplate.find('java_runner', 'runner.java').result(binding)
      end
    end
   
    def self.create_java_path_file java_file, java_package
      begin 
      File.open(java_file, "w+") do |f|
        f.puts BundlerTemplate.find('java_runner', 'path.java').result(binding)
      end
      rescue 
          puts "!!!!!!! Error creating Path.java: #{$!}"
          raise
      end
    end
    
    def self.w msg
      warn(msg) if  ENV['WORDY']
    end

    def self.create_default_config_file config_path, java_class, project_name=nil
      w "Creating default config file in '#{config_path}'  with project_name #{project_name} ..."
      
      Rawr::Configuration.project_name = project_name if project_name

      w "Project name is #{Rawr::Configuration.project_name}"

      File.open(config_path, "w+") do |config_file|
        config_file << "configuration do |c|\n"
        Rawr::Configuration::OPTIONS.each do |option|
          warn "option #{option.name}: #{option.value || option.default}"
          doc_string = option.comment
          doc_string ||= "Undocumented option '#{option.name}'"
          config_file << "\t# #{doc_string}\n"
          config_file << "\t# default value: #{option.default.inspect}\n"
          config_file << "\t#\n"
          case option.name
          when :extra_user_jars
            config_file << "\t#c.extra_user_jars[:data] = { :directory => 'data/images/png',\n"
            config_file << "\t#                             :location_in_jar => 'images',\n"
            config_file << "\t#                             :exclude => /*.bak$/ }\n"
          else
            config_file << "\t#c.#{option.name} = #{option.default.inspect}\n"
          end
          config_file << "\n"
        end
        config_file << "end\n"
      end
    end
  end
end
