module Rawr
  class Command
    def self.fetch_jruby(args=ARGV)
      until args.empty?
        arg = args.shift
        case arg
        when '--fetch-version'
          version = args.shift
        when '--destination'
          destination = args.shift
        end
      end

      version ||= 'current'
      destination ||= Rawr::Configuration.current_config.java_lib_dirs.first

      require 'jruby_release'
      JRubyRelease.get version, destination
    end

    def self.compile_ruby_dirs(src_dirs, dest_dir, jruby_jar, exclude, target_jvm)
      require 'rawr_environment'
      Rawr::ensure_jruby_environment
      require 'jruby_batch_compiler'
      
      #TODO: Set target jvm here
      rawr_dir = File.expand_path(File.dirname(__FILE__))
      compiler_cmd = "require '#{rawr_dir}/jruby_batch_compiler'; " +
                     "Rawr::JRubyBatchCompiler.compile_argv"
      sh 'java', '-jar', jruby_jar, '-e', compiler_cmd, *(src_dirs + [dest_dir])
    end
  end
end
