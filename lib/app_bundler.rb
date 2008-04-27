require 'fileutils'
require 'bundler'

module Rawr
  MAC_PATH = "#{OUTPUT_DIR}/native_deploy/mac"
  MAC_APP_PATH = "#{MAC_PATH}/#{PROJECT_NAME}.app"
  JAVA_APP_DEPLOY_PATH = "#{MAC_APP_PATH}/Contents/Resources/Java"
  
  class AppBundler < Bundler  
    include FileUtils

    def deploy
      create_clean_deployement_directory_structure
      copy_deployment_to JAVA_APP_DEPLOY_PATH
      generate_info_plist
      generate_pkg_info
      deploy_artwork
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
      cp "#{File.dirname(__FILE__)}/GenericJavaApp.icns", "#{MAC_APP_PATH}/Contents/Resources"
      cp "#{File.dirname(__FILE__)}/JavaApplicationStub", "#{MAC_APP_PATH}/Contents/MacOS"
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
  INFO_ENDL
      end
    end
  end
end