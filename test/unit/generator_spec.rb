require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'generator'
require 'fileutils'

describe Rawr::Generator do
  include CustomFileMatchers
  
  before :each do
    @it = Rawr::Generator
  end
  
  it "creates a run config file" do
    @it.create_run_config_file :package_dir => '.', :ruby_source => 'src', :main_ruby_file => 'main.rb', :native_library_dirs => []

    'run_configuration'.should be_existing_file
    #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
    File.should be_size('run_configuration')
    FileUtils.rm_rf 'run_configuration'
  end
  
  it "creates a manifest file" do
    FileUtils.mkdir_p 'rawr-spec-temp-test/META-INF'
    
    @it.create_manifest_file :build_dir => 'rawr-spec-temp-test', :classpath => ['foo', 'bar'], :base_dir => '.', :main_java_file => 'org.rawr.test.Main'
    
    'rawr-spec-temp-test/META-INF/MANIFEST.MF'.should be_existing_file
    #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
    File.should be_size('rawr-spec-temp-test/META-INF/MANIFEST.MF')
    FileUtils.rm_rf 'rawr-spec-temp-test'
  end
  
  # just see if the file is created, and has some content
  it "creates a build configuration file" do
    @it.create_default_config_file('test_configuration.yaml', 'org.rawr.test.Main')
    
    'test_configuration.yaml'.should be_existing_file
    #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
    File.should be_size('test_configuration.yaml')
    FileUtils.rm 'test_configuration.yaml'
  end
  
  it "creates a Java main file" do
    @it.create_java_main_file('TestMain.java', 'org.rawr.test', 'Main')
    
    'TestMain.java'.should be_existing_file
    #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
    File.should be_size('TestMain.java')
    FileUtils.rm 'TestMain.java'
  end
end