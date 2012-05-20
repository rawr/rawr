require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'rawr/rawr_bundler'

describe Rawr::RawrBundler do
  before :each do
    @bundler = Rawr::RawrBundler.new
  end

#  it "converts the classpath into a relative classpath" do
#    @bundler.instance_variable_set(:@base_dir, "/root")
#    @bundler.instance_variable_set(:@classpath, ["/root/foo.rb", "/root/bar.rb"])
#
#    @bundler.send(:relative_classpath).should == ["foo.rb", "bar.rb"]
#  end
#
#  it "uses the relative classpath during the deployment copy" do
#    @bundler.should_receive(:relative_classpath).and_return([])
#
#    @bundler.instance_variable_set(:@base_dir, "/root")
#    @bundler.instance_variable_set(:@package_dir, "/root/package")
#    @bundler.instance_variable_set(:@classpath, ["/root/foo.rb", "/root/bar.rb"])
#    @bundler.stub!(:file_utils).and_return(FileUtils::DryRun)
#
#    @bundler.copy_deployment_to "temp_deploy"
#  end

end
