require 'fileutils'

include FileUtils

#namespace("rawr") do
  namespace :"rawr:bundle" do
    
    desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
    task :app => [:"rawr:jar"] do
      mkdir "dist/native_deploy" unless File.exists? "dist/native_deploy"
      MAC_PATH = "dist/native_deploy/mac"
      `rm -rf #{MAC_PATH}` if File.exists? MAC_PATH
      mkdir MAC_PATH unless File.exists? MAC_PATH

      PROJECT_PATH = "#{MAC_PATH}/#{PROJECT_NAME}.app"
      mkdir PROJECT_PATH
      mkdir "#{PROJECT_PATH}/Contents"
      mkdir "#{PROJECT_PATH}/Contents/MacOS"
      mkdir "#{PROJECT_PATH}/Contents/Resources"
      JAVA_APP_DEPLOY_PATH = "#{PROJECT_PATH}/Contents/Resources/Java"
      mkdir JAVA_APP_DEPLOY_PATH
      `cp -R dist/deploy/* #{JAVA_APP_DEPLOY_PATH.gsub(" ", "\\ ")}`
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
    task :exe do

    end
  end
#end