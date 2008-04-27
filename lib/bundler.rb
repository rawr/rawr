require 'fileutils'

class Bundler
  include FileUtils
  
  def copy_deployment_to(destination_path)
    mkdir_p destination_path
    relative_package_dir = PACKAGE_DIR.gsub("#{BASE_DIR}/", '')
    (Dir.glob("#{PACKAGE_DIR}/**/*").reject{|e| e =~ /\.svn/}.map{|file| file.gsub(BASE_DIR + '/', '')} + CLASSPATH_FILES).flatten.uniq.each do |file|
       FileUtils.mkdir_p("#{destination_path}/#{File.dirname(file).gsub(relative_package_dir, '')}")
       FileUtils.copy(file, "#{destination_path}/#{file.gsub(relative_package_dir, '')}") unless File.directory?(file)
    end
  end
end