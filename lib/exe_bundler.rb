require 'fileutils'
require 'bundler'
require 'platform'

module Rawr
  class ExeBundler < Bundler  
    include FileUtils

    def deploy(options)
      @project_name = options[:project_name]
      @output_dir = options[:output_dir]
      @classpath = options[:classpath]
      @package_dir = options[:package_dir]
      @classpath = options[:classpath]
      @base_dir = options[:base_dir]
      
      launch4j_config_file = "windows-exe.xml"
      mkdir_p "#{options[:output_dir]}/native_deploy"
      windows_path = "#{options[:output_dir]}/native_deploy/windows" 

      copy_deployment_to windows_path


      unless File.exists? launch4j_config_file
        File.open(launch4j_config_file, 'w') do |file|
          file << <<-CONFIG_ENDL
<launch4jConfig>
<dontWrapJar>true</dontWrapJar>
<headerType>0</headerType>
<jar>#{options[:project_name]}.jar</jar>
<outfile>#{options[:project_name]}.exe</outfile>
<errTitle></errTitle>
<jarArgs></jarArgs>
<chdir></chdir>
<customProcName>true</customProcName>
<stayAlive>false</stayAlive>
<icon></icon>
<jre>
  <path></path>
  <minVersion>1.5.0</minVersion>
  <maxVersion></maxVersion>
  <initialHeapSize>0</initialHeapSize>
  <maxHeapSize>0</maxHeapSize>
  <args></args>
</jre>
</launch4jConfig>          
CONFIG_ENDL
        end
      end
      # Hoe doesn't preserve executable permissions outside of the gem/bin directory
      unless Platform.instance.using_windows?
        chmod 0755, "#{File.dirname(__FILE__)}/launch4j/bin/windres"
        chmod 0755, "#{File.dirname(__FILE__)}/launch4j/bin/ld"
      end
      sh "java -jar #{File.dirname(__FILE__)}/launch4j/launch4j.jar #{launch4j_config_file}"
      puts "moving exe to correct directory"
      mv("#{options[:project_name]}.exe", windows_path)
    end
  end
end