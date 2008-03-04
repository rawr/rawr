require 'fileutils'

include FileUtils

#namespace("rawr") do
  namespace :"rawr:bundle" do
    
    desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
    task :app => [:"rawr:jar"] do
      mkdir_p "#{OUTPUT_DIR}/native_deploy"
      MAC_PATH = "#{OUTPUT_DIR}/native_deploy/mac"
      `rm -rf #{MAC_PATH}` if File.exists? MAC_PATH
      mkdir_p MAC_PATH

      PROJECT_PATH = "#{MAC_PATH}/#{PROJECT_NAME}.app"
      mkdir_p PROJECT_PATH
      mkdir_p "#{PROJECT_PATH}/Contents"
      mkdir_p "#{PROJECT_PATH}/Contents/MacOS"
      mkdir_p "#{PROJECT_PATH}/Contents/Resources"
      JAVA_APP_DEPLOY_PATH = "#{PROJECT_PATH}/Contents/Resources/Java"
      copy_deployment_to JAVA_APP_DEPLOY_PATH
      
      File.open "#{PROJECT_PATH}/Contents/Info.plist", "w" do |file|
        file << <<-ENDL
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
  <plist version="0.9">
  <dict>
          <key>CFBundleName</key>
          <string>#{PROJECT_NAME}</string>
          <key>CFBundleVersion</key>
          <string>100.0</string>
          <key>CFBundleAllowMixedLocalizations</key>
          <string>true</string>
          <key>CFBundleExecutable</key>
          <string>JavaApplicationStub</string>
          <key>CFBundleDevelopmentRegion</key>
          <string>English</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
          <key>CFBundleSignature</key>
          <string>????</string>
          <key>CFBundleInfoDictionaryVersion</key>
          <string>6.0</string>
          <key>CFBundleIconFile</key>
          <string>GenericJavaApp.icns</string>
          <key>Java</key>
          <dict>
                  <key>MainClass</key>
                  <string>org.rubyforge.rawr.Main</string>
                  <key>JVMVersion</key>
                  <string>1.5*</string>
                  <key>ClassPath</key>
                          <array>
                            #{
                              CLASSPATH.map {|jar| "<string>$JAVAROOT/#{File.basename(jar)}</string>"}.join("\n")
                             }
                          </array>
                  <key>Properties</key>
                  <dict>
                          <key>apple.laf.useScreenMenuBar</key>
                          <string>true</string>
                  </dict>
          </dict>
  </dict>
  </plist>
  ENDL
      end

      File.open "#{PROJECT_PATH}/Contents/PkgInfo", "w" do |file|
        file << "APPL????"
      end

      cp "#{File.dirname(__FILE__)}/GenericJavaApp.icns", "#{PROJECT_PATH}/Contents/Resources"
      cp "#{File.dirname(__FILE__)}/JavaApplicationStub", "#{PROJECT_PATH}/Contents/MacOS"
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
  <customProcName>false</customProcName>
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
  end
#end

def copy_deployment_to(destination_path)
  mkdir destination_path unless File.exists? destination_path
  relative_package_dir = PACKAGE_DIR.gsub("#{BASE_DIR}/", '')
  (Dir.glob("#{PACKAGE_DIR}/**/*").reject{|e| e =~ /\.svn/}.map{|file| file.gsub(BASE_DIR + '/', '')} + CLASSPATH_FILES).flatten.uniq.each do |file|
     FileUtils.mkdir_p("#{destination_path}/#{File.dirname(file).gsub(relative_package_dir, '')}")
     File.copy(file, "#{destination_path}/#{file.gsub(relative_package_dir, '')}") unless File.directory?(file)
  end
end