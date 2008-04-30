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
end