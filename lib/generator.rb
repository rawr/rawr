module Rawr
  class Generator
    def self.create_run_config_file(options)
      File.open("#{options[:package_dir]}/run_configuration", "w+") do |run_config_file|
        run_config_file << "ruby_source_dir: " + options[:ruby_source] + "\n"
        run_config_file << "main_ruby_file: " + options[:main_ruby_file] + "\n"
        run_config_file << "native_library_dirs: " + options[:native_library_dirs].map{|dir| dir.gsub(options[:base_dir] + '/', '')}.join(" ")
      end
    end
    def self.create_manifest_file(options)
      File.open("#{options[:build_dir]}/META-INF/MANIFEST.MF", "w+") do |manifest_file|
        manifest_file << "Manifest-Version: 1.0\n"
        manifest_file << "Class-Path: " << options[:classpath].map{|file| file.gsub(options[:base_dir] + '/', '')}.join(" ") << " . \n"
        manifest_file << "Main-Class: #{options[:main_java_file]}\n"
      end
    end
    
    def self.create_java_main_file(java_file, java_package, java_class)
      File.open(java_file, "w+") do |java_main_file|
        java_main_file << <<-ENDL
package #{java_package};

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.io.IOException;
import java.net.URL;


import java.util.ArrayList;
import org.jruby.Ruby;
import org.jruby.RubyInstanceConfig;
import org.jruby.javasupport.JavaEmbedUtils;


public class #{java_class}
{
  public static void main(String[] args) throws Exception
  {   
    RubyInstanceConfig config = new RubyInstanceConfig();
    config.setArgv(args);
    Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(0));
    
    String config_yaml = "";
    try{
      java.io.InputStream ins = Main.class.getClassLoader().getResourceAsStream("run_configuration");
      if (ins == null ) {
        System.err.println("Did not find configuration file 'run_configuration', using defaults.");
      }
      else {
        config_yaml = getConfigFileContents(ins);
      }
    }
    catch(IOException ioe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + ioe);
      config_yaml = "";
    }
    catch(java.lang.NullPointerException npe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + npe );
      config_yaml = "";
    }

    String bootRuby = "require 'java'\\n" + 
      "require 'yaml'\\n" + 
      "config_yaml = '" + config_yaml + "'\\n" +
      "if config_yaml.strip.empty?\\n" +
      "  main_file = 'src/main'\\n" +
      "else\\n" +
      "  config_hash = YAML.load( \\"" + config_yaml + "\\" )\\n" + 
      "  $LOAD_PATH.unshift(config_hash['ruby_source_dir'])\\n" + 
      "  main_file = config_hash['main_ruby_file']\\n" + 
      "end\\n\\n" +
      
      "begin\\n" + 
      "  require main_file\\n" + 
      "rescue LoadError => e\\n" + 
      "  warn 'Error starting the application'\\n" + 
      "  warn \\\"\#{e}\\\\n\#{e.backtrace.join(\\\"\\\\n\\\")}\\\"\\n" + 
      "end\\n";
    runtime.evalScriptlet(bootRuby);
  }

  public static URL getResource(String path) {
    return Main.class.getClassLoader().getResource(path);
  }

  private static String getConfigFileContents(InputStream input) 
  throws IOException, java.lang.NullPointerException {

    InputStreamReader isr = new InputStreamReader(input);
    BufferedReader reader = new BufferedReader(isr);
    String line;
    String buf;
    buf = "";
    while ((line = reader.readLine()) != null) {
      buf += line + "\\n";
    }
    reader.close();
    return(buf);
  }
}
ENDL
      end
    end
    
    def self.create_default_config_file(config_path, java_class)
      File.open(config_path, "w+") do |config_file|
        config_file << <<-ENDL
# Name of the created jar file
project_name: change_me

# Directory to create and place produced project files in
output_dir: package

# File to set as main-class in jar manifest
main_java_file: #{java_class}

# Ruby file to invoke when jar is started
main_ruby_file: main

# Location of Ruby source files
ruby_source_dir: src

# Location of Ruby library files
ruby_library_dir: lib/ruby

# Location of Java source files
java_source_dir: src

# Directories that should have ALL their .jar contents loaded on the classpath
# If you wish to only include specific jars from a directory use classpath_files
classpath_dirs:
   - lib/java

# Individual files that should be loaded on the classpath
#classpath_files:
#    - lib/java/jruby-complete.jar
#    - lib/java/swing-layout-1.0.2.jar

# Directory that should be loaded onto the java.library.path 
#native_library_dirs:
#    - lib/java/native

# Directories which you want the coentents of to be copied to the output directory
#package_data_dirs:
#    - lib

# Directories to be added into the jar
#jar_data_dirs:
#    - data

# jar signing values for JNLP bundling.  If you are using a self-signed jar, 
# uncomment the following lines and edit the password.  
# web_start: 
#    self_sign: true
#    self_sign_passphrase: some_password

# JNLP file configuration values.   Uncomment rhe following and edit with your own details
# jnlp:
#    title: Edit your title
#    vendor: Edit your vendor name
#    codebase: http://edit.your.codebase.url
#    homepage_href:  edit.your.homepage
#    description: "Edit your description"
#    offline_allowed: true
#    shortcut_desktop:  true
#    menu_submenu:  Edit your menu sub-menu

#  Java 'keytool' response values.  Uncomment and edit these values if you
#  want to use the 'rawr:keytool' task
# keytool_responses:
#    password: SekritPassword
#    first_and_last_name: Ilya Kuryakin
#    organization: U.N.C.L.E.
#    locality: NYC
#    state_or_province: NY
#    country_code: US

# NOT YET IMPLEMENTED
#pre_processing_task:
#post_processing_task:
ENDL
      end
    end
  end
end
