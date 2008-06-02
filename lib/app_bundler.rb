require 'fileutils'
require 'bundler'

module Rawr
  class AppBundler < Bundler  
    include FileUtils

    def deploy(options)
      @project_name = options[:project_name]
      @output_dir = options[:output_dir]
      @classpath = options[:classpath]
      @package_dir = options[:package_dir]
      @classpath = options[:classpath]
      @base_dir = options[:base_dir]
      
      @mac_path = "#{@output_dir}/native_deploy/mac"
      @mac_app_path = "#{@mac_path}/#{@project_name}.app"
      @java_app_deploy_path = "#{@mac_app_path}/Contents/Resources/Java"
      
      create_clean_deployment_directory_structure(@output_dir, @mac_path, @mac_app_path)
      copy_deployment_to @java_app_deploy_path
      generate_info_plist
      generate_pkg_info
      deploy_info_plist
      deploy_artwork
      deploy_app_stub
    end

    def create_clean_deployment_directory_structure(output_dir, mac_path, mac_app_path)
      mkdir_p "#{output_dir}/native_deploy"

      rm_rf mac_path if File.exists? mac_path

      mkdir_p mac_path
      mkdir_p mac_app_path
      mkdir_p "#{mac_app_path}/Contents"
      mkdir_p "#{mac_app_path}/Contents/MacOS"
      mkdir_p "#{mac_app_path}/Contents/Resources"
    end

    def deploy_artwork
      cp "#{File.expand_path(File.dirname(__FILE__))}/../data/GenericJavaApp.icns", "#{@mac_app_path}/Contents/Resources"
    end
    
    def deploy_app_stub
      stub_destination = "#{@mac_app_path}/Contents/MacOS"
      stub_file = "JavaApplicationStub"
      
      cp "#{File.expand_path(File.dirname(__FILE__))}/../data/#{stub_file}", stub_destination
      chmod 0755, "#{stub_destination}/#{stub_file}"
    end

    def generate_pkg_info
      File.open "#{@mac_app_path}/Contents/PkgInfo", "w" do |file|
        file << "APPL????"
      end
    end

    def deploy_info_plist
      cp "Info.plist", "#{@mac_app_path}/Contents/"
    end
    
    def generate_info_plist
      unless File.exists? "Info.plist"
        File.open "Info.plist", 'w' do |file|
          file << <<-INFO_ENDL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
<plist version="0.9">
<dict>
        <key>CFBundleName</key>
        <string>#{@project_name}</string>
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
                            <string>$JAVAROOT/#{@project_name}.jar</string>
                          #{
                            #CLASSPATH.uniq.map {|jar| "<string>$JAVAROOT/#{@classpath}/#{File.basename(jar)}</string>"}.join("\n")
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
end