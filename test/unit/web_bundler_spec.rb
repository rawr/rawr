require 'spec_helpers'
require 'bundler'
require 'web_bundler'
require 'rexml/document'

describe Rawr::WebBundler do

  BUILD_CONFIGURATION = <<-EOL
      # Name of the created jar file
      project_name: CopyCenter


      # Directory to create and place produced project files in
      output_dir: package

      # File to set as main-class in jar manifest
      main_java_file: org.rubyforge.rawr.Main

      # Ruby file to invoke when jar is started
      main_ruby_file: main

      # Location of Ruby source files
      ruby_source_dir: src

      ruby_library_dir: lib/ruby

      # Location of Java source files
      java_source_dir: src

      # Directories that should have ALL their .jar contents loaded on the classpath
      # If you wish to only include specific jars from a directory use classpath_files
      classpath_dirs:
         - lib/java

      # Individual files that should be loaded on the classpath
      classpath_files:
          - lib/java/gems.jar
          - lib/java/jrubygems-0.4-SNAPSHOT.jar
          - lib/java/jruby-complete.jar
          - lib/java/swing-layout-1.0.3.jar
          - lib/java/derby-10.3.2.1.jar
          - lib/java/jdbc_adapter_internal.jar
          - lib/java/monkeybars-0.6.2.jar
      # Directory that should be loaded onto the java.library.path 
      #native_library_dirs:
      #    - lib/native

      # Directories which you want the coentents of to be copied to the output directory
      package_data_dirs:
          - lib/java

      # Directories to be added into the jar
      #jar_data_dirs:
      #    - data
      #    - gem

      # NOT YET IMPLEMENTED
      #pre_processing_task:
      #post_processing_task:


      web_start: 
        self_sign: true
        self_sign_passphrase: password
        jnlp:
          title: The Foo Bar App
          vendor: HCS
          codebase: http://www.happycamperstudios.com/foo
          homepage_href: '/bar.html'
          description: 'The description' 
          offline_allowed: true
          shortcut_desktop:  true
          menu_submenu:  'Foo Bar'



   EOL



  before :each do
    @web_bundler = Rawr::WebBundler.new
  end




  it "adjusts the path of jars in the classpath " do
    @web_bundler.instance_variable_set(:@base_dir, "/path/to/project/root")
    @web_bundler.instance_variable_set(:@output_dir, "/path/to/project/root/package")
    @web_bundler.instance_variable_set(:@package_dir, "/path/to/project/root/package/deploy")
    @web_bundler.instance_variable_set(:@classpath, ["/root/foo.rb", "/root/bar.rb"])
    path1= 'lib/java/derby-10.3.2.1.jar'
    @web_bundler.to_web_path(path1).should ==  '/path/to/project/root/package/native_deploy/web/lib/java/derby-10.3.2.1.jar'
    path2= '/path/to/project/root/package/deploy/foo.jar'
    @web_bundler.to_web_path(path2).should ==  '/path/to/project/root/package/native_deploy/web/foo.jar'
  end



  it "creates a JNLP string from the web_start JNLP configuration values" do
    config = YAML.load(BUILD_CONFIGURATION )
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

    expected_jnlp_dom = REXML::Document.new(expected_jnlp )

    template_values = {}

    template_values[:project_name]   = 'RawrLib'
    template_values[:codebase]  = 'http://www.happycamperstudios.com/monkeybars/rawrlib'
    template_values[:vendor] = 'Happy Camper Studios'
    template_values[:homepage_href] = '/rawrdocs.html' 
    template_values[:classpath_jnlp_jars]  = "<jar href='lib/java/jruby-complete.jar'/>\n<jar href='lib/java/swing-layout-1.0.3.jar'/>\n<jar href='lib/java/monkeybars-0.6.2.jar'/>"
    template_values[:main_java_file]  = 'RawrLib.jar'
    template_values[:description]  = 'Test JNLP'

    generated_jnlp  = @web_bundler.populate_jnlp_string_template(template_values)
    generated_jnlp_dom = REXML::Document.new(generated_jnlp)

    generated_lines = generated_jnlp_dom.to_s.split( "\n")
    expected_lines = expected_jnlp_dom.to_s.split( "\n")

    generated_lines.each_with_index do   | l, idx |
      l.strip.should == expected_lines[idx].strip
    end

  end


  it "takes a list of jar files and creates a set of resource child elements in the JNLP string" do
    @web_bundler.instance_variable_set(:@base_dir, "/path/to/project/root")
    @web_bundler.instance_variable_set(:@output_dir, "/path/to/project/root/package")
    @web_bundler.instance_variable_set(:@package_dir, "/path/to/project/root/package/deploy")

    @web_bundler.instance_variable_set(:@classpath, %w{ lib/java/jruby-complete.jar lib/java/swing-layout-1.0.3.jar lib/java/monkeybars-0.6.2.jar} )
    @web_bundler.classpath_jnlp_jars.should == "<jar href='lib/java/jruby-complete.jar'/>\n<jar href='lib/java/swing-layout-1.0.3.jar'/>\n<jar href='lib/java/monkeybars-0.6.2.jar'/>"
  end

end