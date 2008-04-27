require 'fileutils'
require 'bundler'

module Rawr
  MAC_PATH = "#{OUTPUT_DIR}/native_deploy/mac"
  MAC_APP_PATH = "#{MAC_PATH}/#{PROJECT_NAME}.app"
  JAVA_APP_DEPLOY_PATH = "#{MAC_APP_PATH}/Contents/Resources/Java"
  
  class AppBundler < Bundler  
    include FileUtils

    def deploy
      create_clean_deployment_directory_structure
      copy_deployment_to JAVA_APP_DEPLOY_PATH
      generate_info_plist
      generate_pkg_info
      deploy_artwork
      deploy_app_stub
    end

    def create_clean_deployment_directory_structure
      mkdir_p "#{OUTPUT_DIR}/native_deploy"

      rm_rf MAC_PATH if File.exists? MAC_PATH

      mkdir_p MAC_PATH
      mkdir_p MAC_APP_PATH
      mkdir_p "#{MAC_APP_PATH}/Contents"
      mkdir_p "#{MAC_APP_PATH}/Contents/MacOS"
      mkdir_p "#{MAC_APP_PATH}/Contents/Resources"
    end

    def deploy_artwork
      cp "#{File.expand_path(File.dirname(__FILE__))}/../data/GenericJavaApp.icns", "#{MAC_APP_PATH}/Contents/Resources"
    end
    
    def deploy_app_stub
      stub_destination = "#{MAC_APP_PATH}/Contents/MacOS"
      stub_file = "JavaApplicationStub"
      
      cp "#{File.expand_path(File.dirname(__FILE__))}/../data/#{stub_file}", stub_destination
      chmod 0755, "#{stub_destination}/#{stub_file}"
    end

    def generate_pkg_info
      File.open "#{MAC_APP_PATH}/Contents/PkgInfo", "w" do |file|
        file << "APPL????"
      end
    end

    def generate_info_plist
      File.open "#{MAC_APP_PATH}/Contents/Info.plist", 'w' do |file|
        file << <<-INFO_ENDL
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
                            <string>$JAVAROOT/#{PROJECT_NAME}.jar</string>
                          #{
                            #CLASSPATH.uniq.map {|jar| "<string>$JAVAROOT/#{CLASSPATH_DIR}/#{File.basename(jar)}</string>"}.join("\n")
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
INFO_ENDL
      end
    end
  end
end