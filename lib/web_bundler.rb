require 'bundler'

module Rawr
  class WebBundler < Bundler
    def self_sign_pass_phrase(options)
      return nil unless options[:web_start]
      return nil unless options[:web_start][:self_sign]
      options[:web_start][:self_sign_passphrase]
    end

    def deploy(options)
      @project_name = options[:project_name]
      @output_dir = options[:output_dir]
      @classpath = options[:classpath]
      @package_dir = options[:package_dir]
      @classpath = options[:classpath]
      @base_dir = options[:base_dir]
      @main_java_file = options[:main_java_file]
      
      web_path = "#{@output_dir}/native_deploy/web"
      mkdir_p web_path
      web_start_config_file = "#{@project_name}.jnlp"
      unless File.exists? web_start_config_file
        File.open(web_start_config_file, 'w') do |file|
          # WARNING: all-permissions needed for security with JRuby!!!!
          file << <<-CONFIG_ENDL
<?xml version="1.0" encoding="UTF-8"?>
<jnlp spec="1.0+" codebase="WEB_PAGE" href="#{@project_name}.jnlp">
<information>
  <title>#{@project_name}</title>
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
  <jar href="#{@project_name}.jar"/>
  #{classpath_jnlp_jars}
</resources>

<application-desc main-class="#{@main_java_file}" />
</jnlp>
CONFIG_ENDL
        end
      end

      copy_deployment_to web_path
      cp web_start_config_file, web_path, :verbose => true
      storepass =  self_sign_pass_phrase(options) ? " -storepass #{self_sign_pass_phrase(options)} " : '' 
      sh "jarsigner -keystore sample-keys #{storepass} #{web_path}/#{@project_name}.jar myself"
      puts "done signing project jar"
      @classpath.each {|jar| 
        sh "jarsigner -keystore sample-keys #{storepass}  #{web_path}/#{jar.gsub(@base_dir, '')} myself"}
    end
    
    def classpath_jnlp_jars
      @classpath.map {|jar| "<jar href=\"#{jar}\"/>"}.join("\n")
    end
  end
end
