require 'configuration'

module Rawr
  class Generator
    def self.create_run_config_file(options)
      File.open(File.join(options.compile_dir, 'run_configuration'), "w+") do |run_config_file|
        run_config_file << "main_ruby_file: " + options.main_ruby_file + "\n"
      end
    end
    
    def self.create_manifest_file(options)
      metainf_dir_path = File.join(options.compile_dir, 'META-INF')
      manifest_path = File.join(metainf_dir_path, 'MANIFEST.MF')
      
      lib_dirs = options.classpath.map {|cp| cp.gsub('../', '')}
      lib_jars = options.jars.keys.map {|key| key.to_s + ".jar"}
      libraries = lib_dirs + lib_jars + ["."]
      
      File.open(manifest_path, "w+") do |manifest_file|
        manifest_file << "Manifest-Version: 1.0\n"
        manifest_file << "Class-Path: " + libraries.join("\n  ") + "\n"
        manifest_file << "Main-Class: " + options.main_java_file + "\n"
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
    Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(0), config);
    String mainRubyFile = "main";
   
    ArrayList<String> config_data = new ArrayList<String>();
    try{
      java.io.InputStream ins = Main.class.getClassLoader().getResourceAsStream("run_configuration");
      if (ins == null ) {
        System.err.println("Did not find configuration file 'run_configuration', using defaults.");
      } else {
        config_data = getConfigFileContents(ins);
      }
    }
    catch(IOException ioe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + ioe);
    }
    catch(java.lang.NullPointerException npe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + npe );
    }

    for(String line : config_data) {
        String[] parts = line.split(":");
        if("main_ruby_file".equals(parts[0].replaceAll(" ", ""))) {
            mainRubyFile = parts[1].replaceAll(" ", "");
        }
    }

    runtime.evalScriptlet("require '" + mainRubyFile + "'");
  }

  public static URL getResource(String path) {
      return Main.class.getClassLoader().getResource(path);
  }

  private static ArrayList<String> getConfigFileContents(InputStream input) throws IOException, java.lang.NullPointerException {
    BufferedReader reader = new BufferedReader(new InputStreamReader(input));
    String line;
    ArrayList<String> contents = new ArrayList<String>();

    while ((line = reader.readLine()) != null) {
      contents.add(line);
    }
    reader.close();
    return(contents);
  }
}
ENDL
      end
    end
    
    def self.create_default_config_file(config_path, java_class)
      puts config_path
      File.open(config_path, "w+") do |config_file|
        config_file << <<-ENDL
configuration do |c|
  c.project_name = #{Rawr::Configuration::OPTIONS[0].default.dump}
  c.output_dir = 'package'
  c.main_ruby_file = 'main'
  c.main_java_file = 'org.rubyforge.rawr.Main'

  # Compile all Ruby and Java files recursively
  # Copy all other files taking into account exclusion filter
  c.source_dirs = ['src', 'lib/ruby']
  c.source_exclude_filter = []

  # Location of the jruby-complete.jar. Override this if your jar lives elsewhere.
  # This allows Rawr to make sure it uses a compatible jrubyc when compiling,
  # so the class files are always compatible, regardless of your system JRuby.
  #c.jruby_jar = 'lib/java/jruby-complete.jar'
  c.compile_ruby_files = true
  #c.java_lib_files = []  
  c.java_lib_dirs = ['lib/java']
  #c.files_to_copy = Dir['other_files/dir/**/*']

  c.target_jvm_version = 1.6
  #c.jars[:data] = { :directory => 'data/images', :location_in_jar => 'images', :exclude => /bak/}
  #c.jvm_arguments = "-server"
  #c.java_library_path = "lib/java/native"

  # Bundler options
  # c.mac_do_not_generate_plist = false
end
ENDL
      end
    end
  end
end
