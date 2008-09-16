#require 'yaml'
require 'singleton'
require 'jar_builder'
#require 'ostruct'
require 'rubygems'
require 'configatron'

# This value needs to stay at the top level so it can be overriden by
# client Rake files
RAWR_CONFIG_FILE = 'build_configuration.rb'

module Rawr
  class Options
    include Singleton
    attr_reader :data
    
    def self.load_configuration(file = RAWR_CONFIG_FILE)
      self.instance.load_configuration file
    end

    def self.data
      self.instance.data
    end

    def load_configuration(file)
      configuration do |c|
        c.project_name = 'ChangeMe'
        c.output_dir = 'package'
        c.main_ruby_file = 'main'
        c.main_java_file = 'org.rubyforge.rawr.Main'

        c.source_dirs = ['src', 'lib/ruby']
        c.source_exclude_filter = []

        c.compile_ruby_files = true
        c.java_lib_files = []  
        c.java_lib_dirs = ['lib/java']
        c.extra_classpath_files = []
        c.target_jvm_version = 1.5

        c.jars = {}
        c.jvm_arguments = ""
      end
      
      configuration_file = File.readlines(file)
      instance_eval configuration_file.join
      process_configuration
    end
    
  private
    def initialize
      @data = OpenStruct.new
    end
    
    def configuration
      yield @data
    end
    
    def process_configuration
      configuration do |c|
        # Setup output directories for the various package types (jar, windows, osx, linux)
        c.base_dir = Dir::pwd
        c.output_dir = "#{c.base_dir}/#{c.output_dir}"
        c.compile_dir = "#{c.output_dir}/classes"
        c.jar_output_dir = "#{c.output_dir}/jar"
        c.windows_output_dir = "#{c.output_dir}/windows"
        c.osx_output_dir = "#{c.output_dir}/osx"
        c.linux_output_dir = "#{c.output_dir}/linux"
        
        # Set up Java lib settings and classpath
        c.java_lib_files.map! {|e| "#{c.base_dir}/#{e}"}
        c.java_lib_dirs.map! {|e| "#{c.base_dir}/#{e}"}
        c.classpath = (c.java_lib_dirs.map{|directory| Dir.glob("#{directory}/**/*.jar")} + c.java_lib_files).flatten
        
        # Set up Jar packing settings
        c.jars_to_build = c.jars.map do |key, jar_settings|
          jar_builder = JarBuilder.new("#{key.to_s}.jar", jar_settings[:directory], jar_settings[:items], jar_settings[:exclude])
          jar_builder.target_in_jar = jar_settings[:location_in_jar] || "/"
          jar_builder
        end
      end

#      load_ruby_options(config)
#      load_java_options(config)
#      load_jars_options(config)
#      load_keytool_responses(config) 
#      load_web_start_options(config) 
#      load_jnlp(config)
    end

#    def load_keytool_responses(config_hash)
#      @options ||= {}
#      @options[:keytool_responses] = config_hash['keytool_responses'] 
#
#      return unless @options[:keytool_responses]
#      _res = config_hash['keytool_responses'] 
#
#      @options[:keytool_responses][:password]  = _res['password'].to_s 
#      @options[:keytool_responses][:first_and_last_name]  = _res['first_and_last_name'].to_s 
#      @options[:keytool_responses][:organization]  = _res['organization'].to_s 
#      @options[:keytool_responses][:locality]  = _res['locality'].to_s 
#      @options[:keytool_responses][:state_or_province]  = _res['state_or_province'].to_s 
#      @options[:keytool_responses][:country_code]  = _res['country_code'].to_s 
#      @options[:keytool_responses]
#    end
#
#    def  load_web_start_options(config_hash)
#      @options ||= {}
#      @options[:web_start] = config_hash['web_start'] 
#
#      return unless @options[:web_start]
#
#      @options[:web_start][:self_sign] =  config_hash['web_start']['self_sign'] 
#      @options[:web_start][:self_sign_passphrase] =  config_hash['web_start']['self_sign_passphrase'] 
#      @options[:web_start][:self_sign_passphrase] =  config_hash['web_start']['self_sign_passphrase'] 
#      @options[:web_start]
#    end
#
#    def load_jnlp(config_hash)
#      (@options[:jnlp] = nil; return ) unless config_hash['jnlp']
#
#      @options[:jnlp] = {}
#      @options[:jnlp][:title] =  config_hash['jnlp']['title']
#      @options[:jnlp][:vendor] =  config_hash['jnlp']['vendor']
#      @options[:jnlp][:codebase] =  config_hash['jnlp']['codebase']
#      @options[:jnlp][:homepage_href] =  config_hash['jnlp']['homepage_href']
#      @options[:jnlp][:description] =  config_hash['jnlp']['description']
#      @options[:jnlp][:offline_allowed] =  config_hash['jnlp']['offline_allowed']
#      @options[:jnlp][:shortcut_desktop] =  config_hash['jnlp']['shortcut_desktop']
#      @options[:jnlp][:menu_submenu] =  config_hash['jnlp']['menu_submenu']
#    end

#    def load_ruby_options(config_hash)
#      @options ||= {}
#      @options[:ruby_source_dir] = "#{@options[:base_dir]}/#{config_hash['ruby_source_dir']}" || "#{@options[:base_dir]}/src"
#      @options[:ruby_library] = config_hash['ruby_library_dir'] # || "lib"
#      @options[:ruby_library_dir] = "#{@options[:base_dir]}/#{config_hash['ruby_library_dir']}" if config_hash['ruby_library_dir']
#      @options[:ruby_source] = config_hash['ruby_source_dir'] || "src"
#      @options[:main_ruby_file] = config_hash['main_ruby_file'] || "main"
#    end

#    def load_java_options(config_hash)
#      @options ||= {}
#      @options[:main_java_file] = config_hash['main_java_file'] || "org.rubyforge.rawr.Main"
#      @options[:java_source_dir] = "#{@options[:base_dir]}/#{config_hash['java_source_dir']}" || "#{@options[:base_dir]}/src"
#      @options[:classpath_dirs] = (config_hash['classpath_dirs'] || []).map {|e| "#{@options[:base_dir]}/#{e}"}
#      @options[:classpath_files] = config_hash['classpath_files'] || []
#      @options[:classpath] = (@options[:classpath_dirs].map{|cp| Dir.glob("#{cp}**/*.jar")} + @options[:classpath_files]).flatten
#      @options[:native_library_dirs] = (config_hash['native_library_dirs'] || []).map {|e| "#{@options[:base_dir]}/#{e}"}
#      @options[:java_target_version] = config_hash['java_target_version'] 
#      @options[:jar_data_dirs] = config_hash['jar_data_dirs'] || []
#      @options[:package_data_dirs] = config_hash['package_data_dirs'] || []
#    end

#    def load_jars_options(config_hash)
#      @options ||= {}
#      @options[:classpath] ||= []
#      @options[:jars] = {}
#      jars_hash = config_hash['jars'] || {}
#      jars_hash.each do |name, jar_options|
#        jar_dir = jar_options['dir'] || '/'
#        jar_dirs = [jar_dir] unless jar_dir.kind_of? Array
#
#        jar_glob = jar_options['glob'] || '**/*'
#        jar_globs = [jar_glob] unless jar_glob.kind_of? Array
#
#        jar_builder = JarBuilder.new
#        jar_builder.name = name
#        jar_builder.dirs = jar_dirs
#        jar_builder.globs = jar_globs
#
#        @options[:jars][name] = jar_builder
#        @options[:classpath] << jar_builder.name
#      end
#    end

  end
end
