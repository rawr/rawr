#require 'yaml'
require 'singleton'
require 'jar_builder'
require 'ostruct'

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
      default_configuration(@data)
      
      configuration_file = File.readlines(file)
      instance_eval configuration_file.join
      process_configuration(@data)
    end
    
  private
    def default_configuration(c)
      c.project_name = 'ChangeMe'
      c.output_dir = 'package'
      c.main_ruby_file = 'main'
      c.main_java_file = 'org.rubyforge.rawr.Main'

      c.copy_to_build = []

      c.source_dirs = ['src', 'lib/ruby']
      c.source_exclude_filter = []

      c.jruby_jar = 'lib/java/jruby-complete.jar'
      c.compile_ruby_files = true
      c.java_lib_files = []
      c.java_lib_dirs = ['lib/java']
      c.files_to_copy = []
      c.target_jvm_version = 1.6
      c.minimum_windows_jvm_version = c.target_jvm_version
      c.jars = {}
      c.jvm_arguments = ""
      c.java_library_path = ""

      c.windows_startup_error_message     = "There was an error starting the application."
      c.windows_bundled_jre_error_message = "There was an error with the bundled JRE for this app."
      c.windows_jre_version_error_message = "This application requires a newer version of Java. Please visit http://www.java.com"
      c.windows_launcher_error_message    = "There was an error launching the application."

      c.do_not_generate_plist = false
    end

    def initialize
      @data = OpenStruct.new
    end
    
    def configuration
      yield @data
    end
    
    def process_configuration(c)
#      configuration do |c|
        # Setup output directories for the various package types (jar, windows, osx, linux)
        c.base_dir = Dir::pwd
        c.output_dir = "#{c.base_dir}/#{c.output_dir}"
        c.compile_dir = "#{c.output_dir}/classes"
        c.jar_output_dir = "#{c.output_dir}/jar"
        c.windows_output_dir = "#{c.output_dir}/windows"
        c.osx_output_dir = "#{c.output_dir}/osx"
        c.linux_output_dir = "#{c.output_dir}/linux"

        c.copy_to_build.each do |copy_hash|
          to = File.join(c.jar_output_dir, copy_hash[:to])
          from = copy_hash[:from] + '/.' # trailing slash makes cp behave differently
          FileUtils.mkdir_p to
          FileUtils.cp_r from, to
        end

        pwd = "#{Dir::pwd}/"
        c.classpath = build_classpath(c, pwd)
        
        c.files_to_copy.map! {|file| file.sub(pwd, '')}
        
        # Set up Jar packing settings
        c.jars_to_build = get_jar_builders(c)
        
        # Check validity of source filters
        if c.source_exclude_filter.kind_of? Array
          c.source_exclude_filter.each{|filter| raise "Invalid source filter: #{filter.inspect}, contents of source filters array must be regular expressions" unless filter.kind_of? Regexp}
        else
          raise "Invalid source filter: #{c.source_exclude_filter.inspect}, source filters must be an array of regular expressions"
        end
#      end
    end

    def build_classpath(config, pwd)
      (config.java_lib_dirs.map { |directory|
          Dir.glob("#{directory}/**/*.jar")
        } + config.java_lib_files).flatten.map!{|file| file.sub(pwd, '')}
    end

    def get_jar_builders(config)
      config.jars.map do |key, jar_settings|
        JarBuilder.new("#{key.to_s}.jar", jar_settings)
      end
    end
  end
end
