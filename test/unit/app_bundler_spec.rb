require 'app_bundler'
require 'spec_helpers'

describe Rawr::AppBundler do
  include CustomFileMatchers
  
  it "uses the main java class option" do
    app_bundler = Rawr::AppBundler.new
    app_bundler.instance_variable_set(:@main_java_class, "foo")
    
    result_string = ""
    File.stub!(:open).and_yield(result_string)
    
    app_bundler.generate_info_plist
    
    result_string.should match(/<key>MainClass<\/key>\s*<string>foo<\/string>/m)
  end
  
  it "creates the proper directory structure for a .app" do
    begin
      Rawr::AppBundler.new.create_clean_deployment_directory_structure("spec-temp", "spec-temp/native_deploy/mac", "spec-temp/native_deploy/mac/RawrSpec.app")
      
      "spec-temp/native_deploy/mac/RawrSpec.app".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/MacOS".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/Resources".should be_existing_file
    ensure
      FileUtils.rm_rf "spec-temp"
      FileUtils.rm_f "Info.plist"
    end
  end
  
  it "creates an Info.plist file if it didn't exist before in the application root" do
    begin
      "Info.plist".should_not be_existing_file
      
      app_bundler = Rawr::AppBundler.new
      app_bundler.generate_info_plist
      
      "Info.plist".should be_existing_file
    ensure
      FileUtils.rm_f "Info.plist"
    end
  end
  
  it "copies the Info.plist file to .app/Contents directory during packaging" do
    begin
      FileUtils.mkdir_p "spec-temp/native_deploy/mac/RawrSpec.app/Contents/"
      File.open("Info.plist", File::CREAT) do |file|
        file << ""
      end
      
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/Info.plist".should_not be_existing_file
      
      app_bundler = Rawr::AppBundler.new
      app_bundler.instance_variable_set(:@mac_app_path, "spec-temp/native_deploy/mac/RawrSpec.app")
      app_bundler.deploy_info_plist
      
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/Info.plist".should be_existing_file
    ensure
      FileUtils.rm_rf "spec-temp"
      FileUtils.rm_f "Info.plist"
    end
  end
end