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
import java.io.IOException;
import java.net.URL;


import java.util.ArrayList;
import org.jruby.Ruby;
import org.jruby.javasupport.JavaEmbedUtils;


public class #{java_class}
{
  public static void main(String[] args) throws Exception
  {   
    Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(0));
    String config_yaml = "";
    try{
      java.io.InputStream ins = Main.class.getClassLoader().getResourceAsStream("run_configuration");
      if (ins == null ) {
        System.err.println( "InputStream ins is null!");
      }
      else {
        config_yaml = grabConfigFileContents(ins);
      }
    }
    catch(IOException e)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using configuration defaults: " + e);
      config_yaml = "";
    }
    catch(java.lang.NullPointerException ee)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using configuration defaults: " + ee );
      config_yaml = "";
    }

    String bootRuby = "require 'java'\\n" + 
      "require 'yaml'\\n" + 
      "$: << 'src'\\n" + 
      "yaml = '" + config_yaml + "' \\n" +
      "begin\\n" + 
      "  raise 'No YAML!' if  yaml.strip.empty?\\n" + 
      "  config_hash = YAML.load( \\"" + config_yaml + "\\" )\\n" + 
      "  $:.unshift(  config_hash['ruby_source_dir'] )\\n" + 
      "  require  config_hash[ 'ruby_source_dir' ] + '/' + config_hash[ 'main_ruby_file' ]\\n" + 
      "rescue Exception \\n" + 
      "  STDERR.puts \\"Error loading config file: \\" + $! + \\"\\nUsing default values.\\"\\n" + 
      "  begin\\n" + 
      "    require 'src/main'\\n" + 
      "  rescue LoadError => e\\n" + 
      "    warn 'Error starting the application'\\n" + 
      "    warn \"#\{e}\\n#\{e.backtrace.join(\"\\n\")}\"\\n" + 
      "  end\\n" + 
      "end\\n";
    runtime.evalScriptlet( bootRuby );
  }

  public static URL getResource(String path) {
    return Main.class.getClassLoader().getResource(path);
  }

  private static String grabConfigFileContents(InputStream input) 
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
ruby_library_dir: lib

# Location of Java source files
java_source_dir: src

# Directories that should have ALL their .jar contents loaded on the classpath
# If you wish to only include specific jars from a directory use classpath_files
classpath_dirs:
   - lib

# Individual files that should be loaded on the classpath
#classpath_files:
#    - lib/jruby-complete.jar
#    - lib/swing-layout-1.0.2.jar

# Directory that should be loaded onto the java.library.path 
#native_library_dirs:
#    - lib/native

# Directories which you want the coentents of to be copied to the output directory
package_data_dirs:
    - lib

# Directories to be added into the jar
#jar_data_dirs:
#    - data

# NOT YET IMPLEMENTED
#pre_processing_task:
#post_processing_task:
ENDL
      end
    end
  end
end