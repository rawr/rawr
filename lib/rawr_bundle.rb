require 'fileutils'

include FileUtils

namespace :"rawr:bundle" do

  desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
  task :app => [:"rawr:jar"] do
    require 'app_bundler'
    Rawr::AppBundler.new.deploy Rawr::Options.instance
  end

  desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
  task :exe => [:"rawr:jar"] do
    LAUNCH_4_J_CONFIG_FILE = "windows-exe.xml"
    mkdir_p "#{OUTPUT_DIR}/native_deploy"
    WINDOWS_PATH = "#{OUTPUT_DIR}/native_deploy/windows" 

    copy_deployment_to WINDOWS_PATH


    unless File.exists? LAUNCH_4_J_CONFIG_FILE
      File.open(LAUNCH_4_J_CONFIG_FILE, 'w') do |file|
        file << <<-CONFIG_ENDL
<launch4jConfig>
<dontWrapJar>true</dontWrapJar>
<headerType>0</headerType>
<jar>#{WINDOWS_PATH}/#{PROJECT_NAME}.jar</jar>
<outfile>#{WINDOWS_PATH}/#{PROJECT_NAME}.exe</outfile>
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

    sh "java -jar #{File.dirname(__FILE__)}/launch4j/launch4j.jar #{LAUNCH_4_J_CONFIG_FILE}"
    puts "moving exe to correct directory"
    mv("#{PROJECT_NAME}.exe", WINDOWS_PATH)
  end
  
  desc "Bundles the jar from rawr:jar into a Java Web Start application (.jnlp)"
  task :web => [:"rawr:jar"] do
    WEB_PATH = "#{OUTPUT_DIR}/native_deploy/web"
    mkdir_p WEB_PATH
    WEB_START_CONFIG_FILE = "#{PROJECT_NAME}.jnlp"
    unless File.exists? WEB_START_CONFIG_FILE
      File.open(WEB_START_CONFIG_FILE, 'w') do |file|
        # WARNING: all-permissions needed for security with JRuby!!!!
        file << <<-CONFIG_ENDL
<?xml version="1.0" encoding="UTF-8"?>
<jnlp spec="1.0+" codebase="WEB_PAGE" href="#{PROJECT_NAME}.jnlp">
<information>
  <title>#{PROJECT_NAME}</title>
  <vendor></vendor>
  <homepage href="." />
  <description></description>
</information>

<offline-allowed/>

<security>
  <all-permissions/>
</security>

<resources>
  <j2se version="1.6"/>
  <j2se version="1.5"/>
  <jar href="#{PROJECT_NAME}.jar"/>
  #{classpath_jnlp_jars}
</resources>

<application-desc main-class="#{MAIN_JAVA_FILE}" />
</jnlp>
CONFIG_ENDL
      end
    end
    
    copy_deployment_to WEB_PATH
    cp WEB_START_CONFIG_FILE, WEB_PATH, :verbose => true
    
    sh "jarsigner -keystore sample-keys #{WEB_PATH}/#{PROJECT_NAME}.jar myself"
    CLASSPATH_FILES.each {|jar| sh "jarsigner -keystore sample-keys #{WEB_PATH}/#{jar} myself"}
  end
end

def classpath_jnlp_jars
  CLASSPATH_FILES.map {|jar| "<jar href=\"#{jar}\"/>"}.join("\n")
end


