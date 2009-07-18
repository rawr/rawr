require 'fileutils'

module Rawr
  class Bundler
    
#    def add_trailing_slash path
#      raise "Nil passed to add_trailing_slash." if path.nil?
#      path << '/' unless path =~ /\/$/
#      path
#    end

    def copy_deployment_to(destination_path)
      FileUtils.mkdir_p destination_path
      FileUtils.cp_r("#{@built_jar_path || @options.built_jar_path}/.", destination_path)
#      relative_base_dir = @package_dir.sub("#{@base_dir}/", '')
#      (relative_files_without_repo + relative_classpath).flatten.uniq.each do |file|
#        file_utils.mkdir_p("#{add_trailing_slash(destination_path)}#{File.dirname(file).sub(relative_base_dir, '')}")
#        file_utils.copy(file, "#{add_trailing_slash(destination_path)}#{file.sub(relative_base_dir, '')}") unless File.directory?(file)
#      end
    end
#
#    private
#
#    def relative_files_without_repo 
#      files_without_repo.map{|file| file.sub(add_trailing_slash(@base_dir), '')}
#    end
#
#    def files_without_repo
#      Dir.glob("#{@package_dir}/**/*").reject{|e| e =~ /\.svn/}
#    end
#
#    def relative_classpath
#      @classpath.map {|file| file.sub(add_trailing_slash(@base_dir), '')}
#    end
  end
end
