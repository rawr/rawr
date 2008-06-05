require 'fileutils'

module Rawr
  class Bundler
    #TODO: Remove in favor of file_utils method. Check other bundlers
    include FileUtils

    def copy_deployment_to(destination_path)
      file_utils.mkdir_p destination_path
      
      relative_base_dir = @package_dir.sub("#{@base_dir}/", '')
      
      files_without_repo = Dir.glob("#{@package_dir}/**/*").reject{|e| e =~ /\.svn/}
      relative_files_without_repo = files_without_repo.map{|file| file.sub(@base_dir + '/', '')}
      
      (relative_files_without_repo + relative_classpath).flatten.uniq.each do |file|
         file_utils.mkdir_p("#{destination_path}/#{File.dirname(file).sub(relative_base_dir, '')}")
         file_utils.copy(file, "#{destination_path}/#{file.sub(relative_base_dir, '')}") unless File.directory?(file)
      end
    end
    
    private
    def relative_classpath
      @classpath.map {|file| file.sub("#{@base_dir}/", '')}
    end
    
    def file_utils
      FileUtils
    end
  end
end