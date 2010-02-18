require 'configuration'

module Rawr
  class Creator
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
        config_file << "configuration do |c|\n"
        Rawr::Configuration::OPTIONS.each do |option|
          doc_string = option.comment
          doc_string ||= "Undocumented option '#{option.name}'"
          config_file << "\t# #{doc_string}\n"
          config_file << "\t# default value: #{option.default.inspect}\n"
          config_file << "\t#\n"
          case option.name
          when :extra_user_jars
            config_file << "\t#c.extra_user_jars[:data] = { :directory => 'data/images/png',\n"
            config_file << "\t#                             :location_in_jar => 'images',\n"
            config_file << "\t#                             :exclude => /*.bak$/ }\n"
          else
            config_file << "\t#c.#{option.name} = #{option.default.inspect}\n"
          end
          config_file << "\n"
        end
        config_file << "end\n"
      end
    end
  end
end
