require 'fileutils'
require 'bundler'
require 'platform'

module Rawr
  class ExeBundler < Bundler  
    include FileUtils

    def deploy(options)
      @project_name = options.project_name
      @classpath = options.classpath
      @main_java_class = options.main_java_file
      @built_jar_path = options.jar_output_dir
      
      @java_app_deploy_path = options.windows_output_dir
      @target_jvm_version = options.target_jvm_version
      @jvm_arguments = options.jvm_arguments

      @launch4j_config_file = "#{@java_app_deploy_path}/configuration.xml"

      copy_deployment_to @java_app_deploy_path

      unless File.exists? @launch4j_config_file
        File.open(@launch4j_config_file, 'w') do |file|
          file << <<-CONFIG_ENDL
<launch4jConfig>
<dontWrapJar>true</dontWrapJar>
<headerType>0</headerType>
<jar>#{@project_name}.jar</jar>
<outfile>#{@built_jar_path}/#{@project_name}.exe</outfile>
<errTitle></errTitle>
<jarArgs></jarArgs>
<chdir></chdir>
<customProcName>true</customProcName>
<stayAlive>false</stayAlive>
<icon></icon>
<jre>
  <path></path>
  <minVersion>#{@target_jvm_version}</minVersion>
  <maxVersion></maxVersion>
  <initialHeapSize>0</initialHeapSize>
  <maxHeapSize>0</maxHeapSize>
  <args>#{@jvm_arguments}</args>
</jre>
</launch4jConfig>          
CONFIG_ENDL
        end
      end
      unless Platform.instance.using_windows?
        chmod 0755, "#{File.dirname(__FILE__)}/launch4j/bin/windres"
        chmod 0755, "#{File.dirname(__FILE__)}/launch4j/bin/ld"
      end
      sh "java -jar #{File.dirname(__FILE__)}/launch4j/launch4j.jar #{@launch4j_config_file}"
    end
  end
end