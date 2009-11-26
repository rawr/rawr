module Rawr
  class Configuration
    
    class << self; attr_accessor :current_config; end
    
    Option = Struct.new(:name, :type, :default, :comment, :value)
    FilePath = String
    
    OPTIONS = [
      Option.new(:project_name, String, File.basename(Dir.pwd)),
      Option.new(:output_dir, FilePath, 'package'),
      
      Option.new(:main_ruby_file, String, 'main'),
      Option.new(:main_java_file, String, 'org.rubyforge.rawr.Main'),
      
      Option.new(:source_dirs, [FilePath], ['src', 'lib/ruby']),
      Option.new(:source_exclude_filter, [Regexp], []),
      Option.new(:jruby_jar, FilePath, 'lib/java/jruby-complete.jar'),
      Option.new(:compile_ruby_files, TrueClass, true), #FIXME: generic boolean type
      Option.new(:java_lib_files, [FilePath], []),
      Option.new(:java_lib_dirs, [FilePath], ['lib/java']),
      Option.new(:files_to_copy, [FilePath], []), #FIXME: maybe needs file.sub(pwd, '')
      
      Option.new(:target_jvm_version, Numeric, 1.6),
      #Option.new(:jars),
      Option.new(:jvm_arguments, [String], ''),
      Option.new(:java_library_path, [String], ''),
      
      Option.new(:extra_user_jars, Hash, Hash.new),
      
      # Platform-specific options
      Option.new(:mac_do_not_generate_plist, false),
    ]
    
    def initialize
      self.class.current_config = self
    end
    
    def self.default
      return self.new
    end
    
    def load_from_file!(file_path)
      configuration_file = File.readlines(file_path).join
      instance_eval(configuration_file)
      self.class.current_config = self
    end
    
    def configuration
      yield self
    end
    
    def option(name)
      OPTIONS.find { |opt| opt.name.to_s == name.to_s }
    end
    
    def method_missing(sym, *args)
      method = sym.to_s
      value = args.first # Assert args.size == 1
      if method.ends_with('=')
        set_option(method[0..-2], value)
      else
        get_option(method)
      end
    end
    
    def set_option(option_name, value)
      opt = option(option_name)
      if opt.nil? then raise "Unknown Rawr option #{option_name}" end
      opt.value = value unless !option_accepts_value?(opt, value, true)
    end
    
    def get_option(option_name)
      opt = option(option_name)
      if opt.nil? then raise "Unknown Rawr option #{option_name}" end
      value = opt.value
      return !value.nil? ? value : opt.default
    end
    
    def option_accepts_value?(option, value, raise_on_mismatch)
      type = option.type
      if type.is_a?(Array)
        base_type = type[0]
        allows_lists = true
      else
        base_type = type
        allows_lists = false
      end
      
      if value.is_a? Array
        if !allows_lists then return false end
        acceptable_value = value.all? { |x| x.is_a?(base_type) }
      else
        acceptable_value = value.is_a?(base_type)
      end
      
      if raise_on_mismatch && !acceptable_value
        raise "#{option.name} must be a #{type}, #{value}:#{value.class} given"
      end
      
      return acceptable_value
    end
    
    
    
    # FIXME: add checks to inner fields
    def jars
      extra_user_jars
    end
    
    
    # Derived, non-configurable settings
    
    def compile_dir
      File.join(self.output_dir, 'classes')
    end
    
    def compiled_java_classes_path
      File.join(self.compile_dir, 'java')
    end
    
    def compiled_ruby_files_path
      File.join(self.compile_dir, 'ruby')
    end
    
    def compiled_non_source_files_path
      File.join(self.compile_dir, 'non-source')
    end
    
    def meta_inf_dir
      File.join(self.compile_dir, "META-INF")
    end
    
    def jar_output_dir
      File.join(self.output_dir, 'jar')
    end
    
    def windows_output_dir
      File.join(self.output_dir, 'windows')
    end
    
    def osx_output_dir
      File.join(self.output_dir, 'osx')
    end
    
    def base_jar_filename
      self.project_name + ".jar"
    end
    
    def base_jar_complete_path
      File.join(self.jar_output_dir, self.base_jar_filename)
    end
    
    def java_source_files
      FileList[self.source_dirs].find_files_and_filter('*.java', self.source_exclude_filter)
    end
    
    def ruby_source_files
      FileList[self.source_dirs].find_files_and_filter('*.rb', self.source_exclude_filter)
    end
    
    def non_source_file_list
      FileList[self.source_dirs].find_files_and_filter('*', self.source_exclude_filter + [/\.(rb|java|class)$/])
    end
    
    def classpath
      pwd = File.join(Dir::pwd, '')
      
      jars = self.java_lib_dirs.map {|directory|
        Dir.glob(File.join(directory, '**' , '*.jar'))
      }.flatten
      
      files = self.java_lib_files
      
      return (jars + files).map{ |file_path| file_path.sub(pwd, '') }
    end
    
    # FIXME: the following fields are required for compatibility with Rawr::Options
    #        document and expose them through the normal option system
    def minimum_windows_jvm_version
      self.target_jvm_version
    end
    
    def windows_startup_error_message
      "There was an error starting the application."
    end
    
    def windows_bundled_jre_error_message
      "There was an error with the bundled JRE for this app."
    end
    
    def windows_jre_version_error_message
      "This application requires a newer version of Java. Please visit http://www.java.com"
    end
    
    def windows_launcher_error_message
      "There was an error launching the application."
    end
  end
end
