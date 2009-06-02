require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'platform'

describe Platform do
  before :each do
    Platform.instance.instance_variable_set(:@using_windows, nil)
    Platform.instance.instance_variable_set(:@using_linux, nil)
    Platform.instance.instance_variable_set(:@using_mac, nil)
  end
  
  it "detects when running on Windows" do
    Platform.class_eval("@@operating_system = 'Windows XP'")
    Platform.instance.should be_using_windows
  end
  
  it "detects when running on the Mac" do
    Platform.class_eval("@@operating_system = 'darwin'")
    Platform.instance.should be_using_mac
  end
  
  it "detects when running on Linux" do
    Platform.class_eval("@@operating_system = 'linux'")
    Platform.instance.should be_using_linux
  end
  
  it "uses ':' for an argument separator in Windows" do
    Platform.class_eval("@@operating_system = 'Windows XP'")
    Platform.instance.argument_delimiter.should == ';'
  end
end