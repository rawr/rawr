require 'bundler'

module Rawr
  class WebBundler < Bundler
    def self_sign_pass_phrase(options)
      return nil unless options[:web_start]
      return nil unless options[:web_start][:self_sign]
      options[:web_start][:self_sign_passphrase]
    end

    def web_path
      "#{@output_dir}/native_deploy/web"
    end

    def add_trailing_slash path
            path << '/' unless path =~ /\/$/
            path

    end

    def deploy(options)
      @project_name = options[:project_name]
      @output_dir = options[:output_dir]
      @classpath = options[:classpath]
      @package_dir = options[:package_dir]
      @classpath = options[:classpath]
      @base_dir = options[:base_dir]
      @base_dir  = add_trailing_slash(@base_dir  )
      
      @main_java_file = options[:main_java_file]


      mkdir_p web_path
      web_start_config_file = "#{@project_name}.jnlp"
      unless File.exists? web_start_config_file
        File.open(web_start_config_file, 'w') do |file|
          # WARNING: all-permissions needed for security with JRuby!!!!
          file << <<-CONFIG_ENDL
<?xml version="1.0" encoding="UTF-8"?>
<jnlp spec="1.0+" codebase="http://127.0.0.1:1347/" href="#{@project_name}.jnlp">
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
        sh "jarsigner -keystore sample-keys #{storepass}  #{to_web_path(jar)} myself"}
    end

    def classpath_jnlp_jars
      @classpath.map {|jar| "<jar href=\"#{jar}\"/>"}.join("\n")
    end


    def to_web_path( path )
      base_dir  = add_trailing_slash(@base_dir)
      package_dir  = add_trailing_slash(@package_dir)
      relative_package_dir = package_dir.sub(base_dir, '' )
      path.sub!(base_dir, '')
      path.sub!(relative_package_dir , '')
      "#{web_path}/#{ path }"
    end
  end
end
