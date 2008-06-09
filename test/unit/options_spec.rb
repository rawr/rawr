require 'options'

describe Rawr::Options do
  it "parses jars: into JarBuilders" do
    jars_hash = {'jars' => {"test.jar" => {'dir' => 'test', 'glob' => '**/*_test.rb'}}}
    
    Rawr::Options.instance.load_jars_options(jars_hash)
    
    Rawr::Options[:jars]['test.jar'].should_not be_nil
  end

  it "adds jars into the classpath from jars: config node" do
    jars_hash = {'jars' => {"test.jar" => {'dir' => 'test', 'glob' => '**/*_test.rb'}}}
    
    Rawr::Options.instance.load_jars_options(jars_hash)
    
    Rawr::Options[:classpath].should include("test.jar")
  end


  it "returns information about web_start configuration when that key is present" do
    web_start_hash = {'web_start' => {'self_sign' => true, 'self_sign_passphrase' => 'password'}}
    
    Rawr::Options.instance.process_configuration(web_start_hash)
    
    Rawr::Options.instance[:web_start].should_not be_nil   
    Rawr::Options.instance[:web_start][:self_sign].should be_true
    Rawr::Options.instance[:web_start][:self_sign_passphrase].should == 'password'   
  end


  it "does not rasise an exception if no JNLP values are present" do
    lambda { Rawr::Options.instance.process_configuration(Hash.new) }.should_not raise_error(Exception)
  end

  it "returns information about JNLP values if present" do
    jnlp_hash = {'jnlp' => {'title' => 'The Foo Bar App',
                            'vendor' => 'HCS',
                            'codebase' => 'http://www.happycamperstudios.com/foo',
                            'homepage_href' => '/bar.html',
                            'description' => 'The description',
                            'offline_allowed' => true,
                            'shortcut_desktop' => true,
                            'menu_submenu' => 'Foo Bar'
                           },
                 'web_start' => {}
                }
    Rawr::Options.instance.process_configuration(jnlp_hash)
    Rawr::Options.instance[:web_start].should_not be_nil
    Rawr::Options.instance[:jnlp][:title].should == 'The Foo Bar App'
    Rawr::Options.instance[:jnlp][:vendor].should == 'HCS'
    Rawr::Options.instance[:jnlp][:codebase].should == 'http://www.happycamperstudios.com/foo'
    Rawr::Options.instance[:jnlp][:homepage_href].should == '/bar.html'
    Rawr::Options.instance[:jnlp][:description].should == 'The description'
    Rawr::Options.instance[:jnlp][:offline_allowed].should == true
    Rawr::Options.instance[:jnlp][:shortcut_desktop].should == true
    Rawr::Options.instance[:jnlp][:menu_submenu].should == 'Foo Bar'
  end


  it "extracts keytool response values from the configuration file if present" do
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
    options = {}
    options['classpath_files'] = ['lib/debug/debug1.jar', 'lib/debug/debug2.jar']
    options['classpath_dirs'] = ['lib/java']
    options['package_dir'] = 'package/deploy'
    options['project_name'] = 'RawrSpec'
    
    Dir.stub!(:glob).and_return(['lib/java/foo1.jar', 'lib/java/foo2.jar'])
    
    Rawr::Options.instance.load_java_options(options)
    
    Rawr::Options.instance[:classpath].should include('lib/debug/debug1.jar')
    Rawr::Options.instance[:classpath].should include('lib/debug/debug2.jar')
    Rawr::Options.instance[:classpath].should include('lib/java/foo1.jar')
    Rawr::Options.instance[:classpath].should include('lib/java/foo2.jar')
  end
end
