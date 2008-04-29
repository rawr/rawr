require 'yaml'

module Rawr
  class Options
    include Singleton
    
    def self.[](key)
      self.instance[key]
    end
    
    def self.load_configuration(file)
      self.instance.load_configuration file
    end
    
    
    def [](key)
      @options[key]
    end
    
    def load_configuration(file='build_configuration.yaml')
      @options = {}
      
      begin
        @config = YAML.load_file file
      rescue Errno::ENOENT
        @config = {}
      end

      @options[:project_name] = @config['project_name'] || "JRuby project"
      @options[:base_dir] = Dir::pwd
      @options[:output_dir] = "#{@options[:base_dir]}/#{@config['output_dir']}" || "#{@options[:base_dir]}/package"
      @options[:build_dir] = "#{@options[:output_dir]}/bin"
      @options[:package_dir] = "#{@options[:output_dir]}/deploy"
      
      load_ruby_options(@config)
      load_java_options(@config)

        
    end
    
    def load_ruby_options(config_hash)
      @options[:ruby_source_dir] = "#{@options[:base_dir]}/#{config_hash['ruby_source_dir']}" || "#{@options[:base_dir]}/src"
      @options[:ruby_library_dir] = "#{@options[:base_dir]}/#{config_hash['ruby_library_dir']}" || "#{@options[:base_dir]}/lib"
      @options[:ruby_source] = config_hash['ruby_source_dir'] || "src"
      @options[:ruby_library] = config_hash['ruby_library_dir'] || "lib"
      @options[:main_ruby_file] = config_hash['main_ruby_file'] || "main"
    end
    
    def load_java_options(config_hash)
      @options[:main_java_file] = config_hash['main_java_file'] || "org.rubyforge.rawr.Main"
      @options[:java_source_dir] = "#{@options[:base_dir]}/#{config_hash['java_source_dir']}" || "#{@options[:base_dir]}/src"
      @options[:classpath_dirs] = (config_hash['classpath_dirs'] || []).map {|e| "#{@options[:base_dir]}/#{e}"}
      @options[:classpath_files] = config_hash['classpath_files'] || []
      @options[:classpath] = (@options[:classpath_dirs].map{|cp| Dir.glob("#{cp}**/*.jar")} + @options[:classpath_files] + ["#{@options[:package_dir]}/#{@options[:project_name]}.jar"]).flatten
      @options[:native_library_dirs] = (config_hash['native_library_dirs'] || []).map {|e| "#{@options[:base_dir]}/#{e}"}
      @options[:jar_data_dirs] = config_hash['jar_data_dirs'] || []
      @options[:package_data_dirs] = config_hash['package_data_dirs'] || []
    end
  end
end