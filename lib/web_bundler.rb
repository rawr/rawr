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
      raise "Nil passed to add_trailing_slash." if path.nil?
      path << '/' unless path =~ /\/$/
      path
    end


    def populate_jnlp_string_template(template_values)
      jnlp = jnlp_string_template.to_s
      jnlp.gsub!('__PROJECT_NAME__', template_values[:project_name]  )
      jnlp.gsub!('__CODEBASE__', template_values[:codebase]  )
      jnlp.gsub!('__DESCRIPTION__', template_values[:description]  )
      jnlp.gsub!('__VENDOR__', template_values[:vendor]  )
      jnlp.gsub!('__HOMEPAGE_HREF__', template_values[:homepage_href]  )
      jnlp.gsub!('__CLASSPATH_JNLP_JARS__', template_values[:classpath_jnlp_jars]  )
      jnlp.gsub!('__MAIN_JAVA_FILE__', template_values[:main_java_file]  )
    end

    def jnlp_string_template
     " <?xml version='1.0' encoding='UTF-8' ?>
<jnlp spec='1.0+' codebase='__CODEBASE__' href='__PROJECT_NAME__.jnlp'>
     <information>
     <title>__PROJECT_NAME__</title>
     <vendor>__VENDOR__</vendor>
     <homepage href='__HOMEPAGE_HREF__' />
     <description>__DESCRIPTION__</description>
     </information>
     <offline-allowed/>
     <security>
     <all-permissions/>
     </security>
     <resources>
     <j2se version='1.6'/>
     <j2se version='1.5'/>
     <jar href='__PROJECT_NAME__.jar'/>
     __CLASSPATH_JNLP_JARS__
     </resources>
     <application-desc main-class='__MAIN_JAVA_FILE__' />
     </jnlp>"
    end


    def template_values(options)
      STDERR.puts( " template_values(options) \n#{options.inspect}" ) if ENV['JAMES_SCA_JDEV_MACHINE']
      template_values = {}  
      template_values[:project_name]   = @project_name 
      template_values[:codebase]  = options[:jnlp][:codebase]
      template_values[:vendor] = options[:jnlp][:vendor]
      template_values[:homepage_href] = options[:jnlp][:homepage_href] 
      template_values[:classpath_jnlp_jars]  = classpath_jnlp_jars
      template_values[:main_java_file]  = options[:main_java_file]
      template_values[:description]  = options[:jnlp][:description] 
      template_values
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
          file << populate_jnlp_string_template(template_values(options))
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

    def remove_dupes classpath_array
      cp = {}
      classpath_array.map {|c| c.sub!( @base_dir, ''); c }
      classpath_array.each { |c| cp[c] = c }
      cp.keys  
    end

    def classpath_jnlp_jars
      remove_dupes(@classpath).map {|jar| "<jar href='#{jar}'/>"}.join("\n")
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
