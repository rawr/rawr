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
      destination ||= './lib/java'

      require 'jruby_release'
      JRubyRelease.get version, destination
    end

    def self.compile_ruby_dirs(src_dirs, dest_dir, jruby_jar='lib/java/jruby-complete.jar', exclude=[], target_jvm='1.5', copy_only=false)
      ruby_source_file_list = src_dirs.inject([]) do |list, directory|
        list << Dir.glob("#{directory}/**/*.rb").
        reject{|file| File.directory?(file)}.
        map!{|file| directory ? file.sub("#{directory}/", '') : file}.
        reject{|file| exclude.inject(false) {|rejected, filter| (file =~ filter) || rejected} }.
        map!{|file| OpenStruct.new(:file => file, :directory => directory)}
      end.flatten!

      ruby_source_file_list.each do |data|
        file = data.file
        directory = data.directory

        if copy_only
          processed_file = file
          target_file = "#{dest_dir}/#{file}"
        else
          relative_dir, name = File.split(file)
          processed_file = Java::org::jruby::util::JavaNameMangler.mangle_filename_for_classpath(file, Dir.pwd, "", true) + '.class'
          target_file = "#{dest_dir}/#{processed_file}"
        end

        if file_is_newer?("#{directory}/#{file}", target_file)
          FileUtils.mkdir_p(File.dirname("#{dest_dir}/#{processed_file}"))

          if copy_only
            File.copy("#{directory}/#{processed_file}", "#{dest_dir}/#{processed_file}")
          else
            # There's no jrubyc.bat/com/etc for Windows. jruby -S works universally here
            # TODO: Speed up compiling by not invoking java for each file...
            sh "java -jar #{jruby_jar} -S jrubyc #{directory}/#{file}"
            File.move("#{directory}/#{processed_file}", "#{dest_dir}/#{processed_file}")
          end
        end
      end
    end
  end
end