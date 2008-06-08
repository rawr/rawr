require 'spec_helpers'
require 'bundler'
require 'web_bundler'

describe Rawr::WebBundler do
  before :each do
    @web_bundler = Rawr::WebBundler.new
  end



  it " extracts the JNLP template  values from the Options object" do
  end

  it "adjusts the path of jars in the classpath " do
    @web_bundler.instance_variable_set(:@base_dir, "/path/to/project/root")
    @web_bundler.instance_variable_set(:@output_dir, "/path/to/project/root/package")
    @web_bundler.instance_variable_set(:@package_dir, "/path/to/project/root/package/deploy")

    @web_bundler.instance_variable_set(:@classpath, ["/root/foo.rb", "/root/bar.rb"])

    path1= 'lib/java/derby-10.3.2.1.jar'
    @web_bundler.to_web_path( path1 ).should ==  '/path/to/project/root/package/native_deploy/web/lib/java/derby-10.3.2.1.jar'
    path1= '/path/to/project/root/package/deploy/foo.jar'
    @web_bundler.to_web_path( path1 ).should ==  '/path/to/project/root/package/native_deploy/web/foo.jar'
  end



  it "creates a JNLP string from the web_start JNLP configuration values" do
    config = YAML.load(BUILD_CONFIGURATION )

  end





end