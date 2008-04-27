module Rawr; end
Rawr::OUTPUT_DIR = "spec-temp"
Rawr::PROJECT_NAME = "RawrSpec"

require 'app_bundler'

module CustomFileMatchers
  class BeExistingFile
    def initialize; end

    def matches?(target)
      @target = target
      File.exists? @target
    end

    def failure_message
      "expected existing file #{@target.inspect}"
    end

    def negative_failure_message
      "expected no existing file #{@target.inspect}"
    end
  end
  
  def be_existing_file
    BeExistingFile.new
  end
end

describe Rawr::AppBundler do
  include CustomFileMatchers
  
  it "creates the proper directory structure" do
    begin
      Rawr::AppBundler.new.create_clean_deployment_directory_structure
      
      "spec-temp/native_deploy/mac/RawrSpec.app".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/MacOS".should be_existing_file
      "spec-temp/native_deploy/mac/RawrSpec.app/Contents/Resources".should be_existing_file
    ensure
      FileUtils.rm_rf Rawr::OUTPUT_DIR
    end
  end
end