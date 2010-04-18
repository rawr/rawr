require 'ostruct'
require 'jruby/jrubyc'

module Rawr
  class JRubyBatchCompiler
    def self.compile_argv
      dest_dir = ARGV.pop
      # TODO: add ability to carry options through
      new.compile_dirs(ARGV, dest_dir)
    end

    def compile_dirs(src_dirs, dest_dir, options={})
      puts "   compile_dirs has src_dirs = #{src_dirs.inspect}"

      #options[:jruby_jar]  ||= 'lib/java/jruby-complete.jar'
      options[:exclude]    ||= []
      options[:target_jvm] ||= '1.6'

      #TODO: Allow for copy-only and some other options
      ruby_globs = glob_ruby_files(src_dirs, options[:exclude])

      ruby_globs.each do |glob_data|
        puts  "   ruby_globs.each has glob_data = #{glob_data.inspect}"
        files     = glob_data.files
        directory = glob_data.directory
        
        next if files.empty? # Otherwise jrubyc breaks since we cannot compile nothing

        file_set = files.map {|file| "#{directory}/#{file}"}
        raise "Empty file set in #{__FILE__}." if file_set.empty?
        puts "    Go compile #{file_set.inspect}"
        begin
          # JRuby >= 1.5
          compiler = JRuby::Compiler
        rescue NameError => e
          # JRuby 1.4
          # XXX: remove once JRuby 1.4 is no longer supported
          compiler = JRubyCompiler
        end
        compiler.compile_files(file_set, directory, '', dest_dir)
      end
    end

    def glob_ruby_files(src_dirs, excludes)
      src_dirs.inject([]) do |file_globs, directory|
        glob = Dir.glob("#{directory}/**/*.rb")
        puts "   glob_ruby_files has directory '#{directory}' glob #{glob.inspect}"
        reject_directories!(glob)
        strip_directory!(glob, directory)
        reject_excluded_matches!(glob, excludes)
        puts "files for #{directory}: #{glob.size}"
        file_globs << OpenStruct.new(:files => glob, :directory => directory)
        file_globs
      end
    end

    def strip_directory!(dir_globs, directory)
      dir_globs.map! {|file| file.sub("#{directory}/", '')}
    end

    def reject_directories!(glob)
      glob.reject! {|file| File.directory?(file)}
    end

    def reject_excluded_matches!(dir_globs, excludes)
      dir_globs.reject! do |file|
        excludes.any? {|exclude| file =~ exclude}
      end
    end

    def self.compile_ruby_dirs(src_dirs, dest_dir, jruby_jar='lib/java/jruby-complete.jar', exclude=[], target_jvm='1.6')
      ruby_source_file_list = src_dirs.inject([]) do |list, directory|
        list << Dir.glob("#{directory}/**/*.rb").
          #reject{|file| File.directory?(file)}.
          map!{|file| directory ? file.sub("#{directory}/", '') : file}.
          #reject{|file| exclude.inject(false) {|rejected, filter| (file =~ filter) || rejected} }.
          map!{|file| OpenStruct.new(:file => file, :directory => directory)}
      end.flatten!

      ruby_source_file_list.each do |data|
        file = data.file
        directory = data.directory

        relative_dir, name = File.split(file)
        processed_file = Java::org::jruby::util::JavaNameMangler.mangle_filename_for_classpath(file, Dir.pwd, "", true) + '.class'
        target_file = "#{dest_dir}/#{processed_file}"

        if file_is_newer?("#{directory}/#{file}", target_file)
          FileUtils.mkdir_p(File.dirname("#{dest_dir}/#{processed_file}"))

          # There's no jrubyc.bat/com/etc for Windows. jruby -S works universally here
          # TODO: Speed up compiling by not invoking java for each file...
          sh "java -jar #{jruby_jar} -S jrubyc #{directory}/#{file}"
          File.move("#{directory}/#{processed_file}", "#{dest_dir}/#{processed_file}")
        end
      end
    end

  end
end
