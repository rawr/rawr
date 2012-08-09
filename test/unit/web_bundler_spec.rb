require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'rawr/rawr_bundler'
require 'rawr/web_bundler'
require 'rexml/document'

#
# The Web Bundler is not supported right now. Tests left for reference.
# Maybe it will be supported in a later release!
#

describe Rawr::WebBundler do
  before :each do
    @web_bundler = Rawr::WebBundler.new
  end

  it "adjusts the path of jars in the classpath " do
    pending
    @web_bundler.instance_variable_set(:@base_dir, "/path/to/project/root")
    @web_bundler.instance_variable_set(:@output_dir, "/path/to/project/root/package")
    @web_bundler.instance_variable_set(:@package_dir, "/path/to/project/root/package/deploy")
    @web_bundler.instance_variable_set(:@classpath, ["/root/foo.rb", "/root/bar.rb"])
    path1 = 'lib/java/derby-10.3.2.1.jar'
    @web_bundler.to_web_path(path1).should == '/path/to/project/root/package/native_deploy/web/lib/java/derby-10.3.2.1.jar'
    path2 = '/path/to/project/root/package/deploy/foo.jar'
    @web_bundler.to_web_path(path2).should == '/path/to/project/root/package/native_deploy/web/foo.jar'
  end

  it "creates a JNLP string from the web_start JNLP configuration values" do
    pending
    expected_jnlp = <<-EXPECTED_JNLP
    <?xml version='1.0' encoding='UTF-8' ?>
<jnlp spec='1.0+' codebase='http://www.happycamperstudios.com/monkeybars/rawrlib' href='RawrLib.jnlp'>
     <information>
     <title>RawrLib</title>
     <vendor>Happy Camper Studios</vendor>
     <homepage href='/rawrdocs.html'  />
     <description>Test JNLP</description>
     </information>
     <offline-allowed/>
     <security>
     <all-permissions/>
     </security>
     <resources>
     <j2se version='1.6'/>
     <j2se version='1.5'/>
     <jar href='RawrLib.jar'/>
     <jar href="lib/java/jruby-complete.jar"/>
     <jar href="lib/java/swing-layout-1.0.3.jar"/> 
     <jar href="lib/java/monkeybars-0.6.2.jar"/>
     </resources>
     <application-desc main-class='RawrLib.jar' />
     </jnlp>
    EXPECTED_JNLP

    expected_jnlp_dom = REXML::Document.new(expected_jnlp)

    template_values = {}

    template_values[:project_name] = 'RawrLib'
    template_values[:codebase] = 'http://www.happycamperstudios.com/monkeybars/rawrlib'
    template_values[:vendor] = 'Happy Camper Studios'
    template_values[:homepage_href] = '/rawrdocs.html' 
    template_values[:classpath_jnlp_jars] = "<jar href='lib/java/jruby-complete.jar'/>\n<jar href='lib/java/swing-layout-1.0.3.jar'/>\n<jar href='lib/java/monkeybars-0.6.2.jar'/>"
    template_values[:main_java_file] = 'RawrLib.jar'
    template_values[:description] = 'Test JNLP'

    generated_jnlp = @web_bundler.populate_jnlp_string_template(template_values)
    generated_jnlp_dom = REXML::Document.new(generated_jnlp)

    generated_lines = generated_jnlp_dom.to_s.split( "\n").compact
    expected_lines = expected_jnlp_dom.to_s.split( "\n").compact
    
    generated_lines.delete_if {|line| line.empty? }
    expected_lines.delete_if {|line| line.empty? }
    
    generated_lines.each_with_index do |line, index|
      line.strip.should == expected_lines[index].strip
    end
  end


  it "takes a list of jar files and creates a set of resource child elements in the JNLP string" do
    pending
    @web_bundler.instance_variable_set(:@base_dir, "/path/to/project/root")
    @web_bundler.instance_variable_set(:@output_dir, "/path/to/project/root/package")
    @web_bundler.instance_variable_set(:@package_dir, "/path/to/project/root/package/deploy")

    @web_bundler.instance_variable_set(:@classpath, %w{lib/java/jruby-complete.jar lib/java/swing-layout-1.0.3.jar lib/java/monkeybars-0.6.2.jar})
    @web_bundler.classpath_jnlp_jars.should == "<jar href='lib/java/jruby-complete.jar'/>\n<jar href='lib/java/swing-layout-1.0.3.jar'/>\n<jar href='lib/java/monkeybars-0.6.2.jar'/>"
  end
end
