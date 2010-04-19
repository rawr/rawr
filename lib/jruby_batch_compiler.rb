require 'ostruct'
require 'jruby/jrubyc'

module Rawr
  class JRubyBatchCompiler
    def compile_dirs(src_dirs, dest_dir, options={})
      puts "   compile_dirs has src_dirs = #{src_dirs.inspect}"
      
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
  end
end
