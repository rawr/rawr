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

    def populate_jnlp_string_template(template_values)
     <<-JNLP
<?xml version='1.0' encoding='UTF-8' ?>
  <jnlp spec='1.0+' codebase='#{template_values[:codebase]}' href='#{template_values[:project_name]}.jnlp'>
    <information>
    <title>#{template_values[:project_name]}</title>
    <vendor>#{template_values[:vendor]}</vendor>
    <homepage href='#{template_values[:homepage_href]}' />
    <description>#{template_values[:description]}</description>
  </information>

  <offline-allowed/>

  <security>
    <all-permissions/>
  </security>

  <resources>
    <j2se version='1.6'/>
    <j2se version='1.5'/>
    <jar href='#{template_values[:project_name]}.jar'/>
      #{template_values[:classpath_jnlp_jars]}
  </resources>

  <application-desc main-class='#{template_values[:main_java_file]}' />
</jnlp>
     JNLP
    end


    def template_values(options)
      values = {}  
      values[:project_name]   = @project_name 
      values[:codebase]  = options[:jnlp][:codebase]
      values[:vendor] = options[:jnlp][:vendor]
      values[:homepage_href] = options[:jnlp][:homepage_href] 
      values[:classpath_jnlp_jars]  = classpath_jnlp_jars
      values[:main_java_file]  = options[:main_java_file]
      values[:description]  = options[:jnlp][:description] 
      values
    end

    def in_root_dir?(file)
      file !~ /\//
    end

    def copy_deployment_to(destination_path)
      file_utils.mkdir_p destination_path
      relative_base_dir = @package_dir.sub("#{add_trailing_slash(@base_dir)}", '')
      (relative_files_without_repo + relative_classpath).flatten.uniq.each do |file|
        new_dir = "#{add_trailing_slash(destination_path)}#{File.dirname(file).sub(relative_base_dir, '')}"
        file_utils.mkdir_p(new_dir)
        file_utils.copy(file, "#{add_trailing_slash(destination_path)}#{file.sub(relative_base_dir, '')}") unless File.directory?(file) || in_root_dir?(file)
      end
    end

    def deploy(options)
      @project_name = options[:project_name]
      @output_dir = options[:output_dir]
      @classpath = options[:classpath]
      @package_dir = options[:package_dir]
      @base_dir  = add_trailing_slash(options[:base_dir])
      @main_java_file = options[:main_java_file]
      @project_jar = 

      file_utils.mkdir_p web_path

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
      @classpath.each {|jar| sh "jarsigner -keystore sample-keys #{storepass}  #{to_web_path(jar).strip} myself" }
    end


    def classpath_jnlp_jars
      @classpath.map {|jar| "<jar href='#{jar}'/>"}.join("\n")
    end


    def to_web_path(path)
      base_dir = add_trailing_slash(@base_dir)
      package_dir = add_trailing_slash(@package_dir)
      relative_package_dir = package_dir.sub(base_dir, '')
      path.sub!(base_dir, '')
      path.sub!(relative_package_dir , '')
      "#{web_path}/#{path}"
    end
  end
end
