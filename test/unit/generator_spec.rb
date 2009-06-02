require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'generator'
require 'fileutils'

describe Rawr::Generator do
  include CustomFileMatchers
  
  before :each do
    @generator = Rawr::Generator
    @config = OpenStruct.new
  end
  
  it "creates a run config file" do
    begin
      @config.package_dir         = '.'
      @config.ruby_source         = 'src'
      @config.main_ruby_file      = 'main.rb'
      @config.compile_dir         = '.'
      @config.native_library_dirs = []

      @generator.create_run_config_file @config

      'run_configuration'.should be_existing_file
      #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
      File.should be_size('run_configuration')
    ensure # TODO: condisder moving to after block
      FileUtils.rm_rf 'run_configuration'
    end
  end
  
  it "creates a manifest file" do
    begin
      FileUtils.mkdir_p 'rawr-spec-temp-test/META-INF'

      @config.build_dir      = 'rawr-spec-temp-test'
      @config.classpath      = ['foo', 'bar']
      @config.base_dir       = '.'
      @config.main_java_file = 'org.rawr.test.Main'
      @config.jars           = {}
      @config.compile_dir    = 'rawr-spec-temp-test'
      @generator.create_manifest_file @config

      'rawr-spec-temp-test/META-INF/MANIFEST.MF'.should be_existing_file
      #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
      File.should be_size('rawr-spec-temp-test/META-INF/MANIFEST.MF')
    ensure # TODO: Consider moving to after block
      FileUtils.rm_rf 'rawr-spec-temp-test'
    end
  end
  
  # just see if the file is created, and has some content
  it "creates a build configuration file" do
    @generator.create_default_config_file('test_configuration.yaml', 'org.rawr.test.Main')
    
    'test_configuration.yaml'.should be_existing_file
    #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
    File.should be_size('test_configuration.yaml')
    FileUtils.rm 'test_configuration.yaml'
  end
  
  it "creates a Java main file" do
    @generator.create_java_main_file('TestMain.java', 'org.rawr.test', 'Main')
    
    'TestMain.java'.should be_existing_file
    #TODO: This is an awful test, refactor into CustomFileMatchers for better self-documenting code
    File.should be_size('TestMain.java')
    FileUtils.rm 'TestMain.java'
  end
end