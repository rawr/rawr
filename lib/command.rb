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

    def self.compile_ruby_dirs(src_dirs, dest_dir, exclude, target_jvm)
      require 'rawr_environment'
      Rawr::ensure_jruby_environment
      require 'jruby_batch_compiler'
      
      options = Hash.new
      options[:targer_jvm] = target_jvm
      options[:exclude] = exclude
      JRubyBatchCompiler.new.compile_dirs(src_dirs, dest_dir, options)
    end
  end
end
