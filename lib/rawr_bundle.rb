require 'fileutils'

include FileUtils

namespace :"rawr:bundle" do

  desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
  task :app => [:"rawr:jar"] do
    require 'app_bundler'
    Rawr::AppBundler.new.deploy Rawr::Options.instance
  end

  desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
  task :exe => [:"rawr:jar"] do
    require 'exe_bundler'
    Rawr::ExeBundler.new.deploy Rawr::Options.instance
  end
  
  desc "Bundles the jar from rawr:jar into a Java Web Start application (.jnlp)"
  task :web => [:"rawr:jar"] do
    web_path = "#{Rawr::Options[:output_dir]}/native_deploy/web"
    mkdir_p web_path
    web_start_config_file = "#{Rawr::Options[:project_name]}.jnlp"
    unless File.exists? web_start_config_file
      File.open(web_start_config_file, 'w') do |file|
        # WARNING: all-permissions needed for security with JRuby!!!!
        file << <<-CONFIG_ENDL
<?xml version="1.0" encoding="UTF-8"?>
<jnlp spec="1.0+" codebase="WEB_PAGE" href="#{Rawr::Options[:project_name]}.jnlp">
<information>
  <title>#{Rawr::Options[:project_name]}</title>
  <vendor></vendor>
  <homepage href="." />
  <description></description>
</information>

<offline-allowed/>

<security>
  <all-permissions/>
</security>

<resources>
  <j2se version="1.6"/>
  <j2se version="1.5"/>
  <jar href="#{Rawr::Options[:project_name]}.jar"/>
  #{classpath_jnlp_jars}
</resources>

<application-desc main-class="#{Rawr::Options[:main_java_file]}" />
</jnlp>
CONFIG_ENDL
      end
    end
    
    copy_deployment_to web_path
    cp web_start_config_file, web_path, :verbose => true
    
    sh "jarsigner -keystore sample-keys #{web_path}/#{Rawr::Options[:project_name]}.jar myself"
    CLASSPATH_FILES.each {|jar| sh "jarsigner -keystore sample-keys #{web_path}/#{jar} myself"}
  end
end

def classpath_jnlp_jars
  Rawr::Options[:classpath_files].map {|jar| "<jar href=\"#{jar}\"/>"}.join("\n")
end


