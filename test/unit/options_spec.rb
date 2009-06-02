require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'options'

describe Rawr::Options do
  before :each do
    @config = OpenStruct.new
    Rawr::Options.instance.send(:default_configuration, @config)
  end
  it "parses jars: into JarBuilders" do
    @config.jars = {"test.jar" => {:directory => 'test', 'glob' => '**/*_test.rb'}}
    results = Rawr::Options.instance.send(:get_jar_builders, @config)
    
    results.should_not be_nil
  end

  # Not sure this is needed, since jars built by Rawr are put on ., which is on the classpath
#  it "adds jars into the classpath from jars: config node" do
#    config = OpenStruct.new
#    config.jars = {"test.jar" => {:directory => 'test', 'glob' => '**/*_test.rb'}}
#
#    results = Rawr::Options.instance.send(:get_jar_builders, config)
#
#    Rawr::Options[:classpath].should include("test.jar")
#  end


  it "returns information about web_start configuration when that key is present" do
#    pending
    @config.web_start = {:self_sign => true, :self_sign_passphrase => 'password'}
    Rawr::Options.instance.send(:process_configuration, @config)
    
    @config.web_start.should_not be_nil
    @config.web_start[:self_sign].should be_true
    @config.web_start[:self_sign_passphrase].should == 'password'
  end


  it "does not rasise an exception if no JNLP values are present" do
    pending
    lambda { Rawr::Options.instance.send(:process_configuration, @config) }.should_not raise_error(Exception)
  end

  it "returns information about JNLP values if present" do
#    pending
    @config.jnlp = {:title            => 'The Foo Bar App',
                  :vendor           => 'HCS',
                  :codebase         => 'http://www.happycamperstudios.com/foo',
                  :homepage_href    => '/bar.html',
                  :description      => 'The description',
                  :offline_allowed  => true,
                  :shortcut_desktop => true,
                  :menu_submenu     => 'Foo Bar'
                 }
    @config.web_start = {}
    Rawr::Options.instance.send(:process_configuration, @config)
    @config.web_start.should_not be_nil
    @config.jnlp[:title].should == 'The Foo Bar App'
    @config.jnlp[:vendor].should == 'HCS'
    @config.jnlp[:codebase].should == 'http://www.happycamperstudios.com/foo'
    @config.jnlp[:homepage_href].should == '/bar.html'
    @config.jnlp[:description].should == 'The description'
    @config.jnlp[:offline_allowed].should == true
    @config.jnlp[:shortcut_desktop].should == true
    @config.jnlp[:menu_submenu].should == 'Foo Bar'
  end


  it "extracts keytool response values from the configuration file if present" do
    pending
    keytool_hash = {'keytool_responses' => {'password' => 'sekrit',
                                           'first_and_last_name' => 'Napolean Solo',
                                           'organization' => 'U.N.C.L.E.',
                                           'locality' => 'NYC',
                                           'state_or_province' => 'NY',
                                           'country_code' => 'US'
                                          }
                   }
                   
    keytool_responses = Rawr::Options.instance.load_keytool_responses(keytool_hash)
    
    keytool_responses[:password].should  == 'sekrit'
    keytool_responses[:first_and_last_name].should  == 'Napolean Solo'
    keytool_responses[:organization].should  == 'U.N.C.L.E.'
    keytool_responses[:locality].should  == 'NYC'
    keytool_responses[:state_or_province].should  == 'NY'
    keytool_responses[:country_code].should  == 'US'
  end

  it "creates a classpath entry without the deploy dir" do
    @config.java_lib_files = ['lib/debug/debug1.jar', 'lib/debug/debug2.jar']
    @config.java_lib_dirs = ['lib/java']
    @config.package_dir = 'package/deploy'
    @config.project_name = 'RawrSpec'
    
    Dir.stub!(:glob).and_return(['lib/java/foo1.jar', 'lib/java/foo2.jar'])
    
    Rawr::Options.instance.send(:process_configuration, @config)

    @config.classpath.should include('lib/debug/debug1.jar')
    @config.classpath.should include('lib/debug/debug2.jar')
    @config.classpath.should include('lib/java/foo1.jar')
    @config.classpath.should include('lib/java/foo2.jar')
  end
end
