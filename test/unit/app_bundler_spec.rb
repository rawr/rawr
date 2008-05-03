require 'app_bundler'
require 'spec_helpers'

describe Rawr::AppBundler do
  include CustomFileMatchers
  
  it "creates the proper directory structure" do
    begin
      Rawr::AppBundler.new.create_clean_deployment_directory_structure("spec-temp", "spec-temp/native_deploy/mac", "spec-temp/native_deploy/mac/RawrSpec.app")
      
      "spec-temp/native_deploy/mac/RawrSpec.app".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/MacOS".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/Resources".should be_existing_file
    ensure
      FileUtils.rm_rf "spec-temp"
    end
  end
end