require 'fileutils'

module Rawr
  class Bundler
    include FileUtils

    def copy_deployment_to(destination_path)
      mkdir_p destination_path
      
      relative_package_dir = @package_dir.gsub("#{@base_dir}/", '')
      
      files_without_repo = Dir.glob("#{@package_dir}/**/*").reject{|e| e =~ /\.svn/}
      relative_files_without_repo = files_without_repo.map{|file| file.gsub(@base_dir + '/', '')}
      
      (relative_files_without_repo + @classpath).flatten.uniq.each do |file|
         FileUtils.mkdir_p("#{destination_path}/#{File.dirname(file).gsub(relative_package_dir, '')}")
         FileUtils.copy(file, "#{destination_path}/#{file.gsub(relative_package_dir, '')}") unless File.directory?(file)
      end
    end
  end
end