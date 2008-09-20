module Rawr
  class Generator
    def self.create_run_config_file(options)
      File.open("#{options.compile_dir}/run_configuration", "w+") do |run_config_file|
        run_config_file << "main_ruby_file: " + options.main_ruby_file + "\n"
      end
    end
    def self.create_manifest_file(options)
      
      File.open("#{options.compile_dir}/META-INF/MANIFEST.MF", "w+") do |manifest_file|
        manifest_file << "Manifest-Version: 1.0\n"
        manifest_file << "Class-Path: " << options.classpath.join(" ") << " . \n"
        manifest_file << "Main-Class: #{options.main_java_file}\n"
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
  c.project_name = 'ChangeMe'
  c.output_dir = 'package'
  c.main_ruby_file = 'main'
  c.main_java_file = 'org.rubyforge.rawr.Main'

  # Compile all Ruby and Java files recursively
  # Copy all other files taking into account exclusion filter
  c.source_dirs = ['src', 'lib/ruby']
  c.source_exclude_filter = []

  c.compile_ruby_files = true
  #c.java_lib_files = []  
  c.java_lib_dirs = ['lib/java']

  c.target_jvm_version = 1.5
  #c.jars[:data] = { :directory => 'data/images', :location_in_jar => 'images', :exclude => /bak/}
  #c.jvm_arguments = ""
        ENDL
      end
    end
  end
end
