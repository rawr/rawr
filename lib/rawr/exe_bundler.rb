require 'fileutils'

require 'rawr/bundler'
require 'rawr/platform'
require 'rawr/bundler_template'

module Rawr
  class ExeBundler < Bundler  
    include FileUtils

    def link_launch4j_bin(prefix, root_path)
      return if File.exists? "#{root_path}/launch4j/bin"
      case prefix
      when 'win'
        FileUtils.mv "#{root_path}/launch4j/bin-#{prefix}", "#{root_path}/launch4j/bin"
      else
        chmod 0755, "#{root_path}/launch4j/bin-#{prefix}/windres"
        chmod 0755, "#{root_path}/launch4j/bin-#{prefix}/ld"
        sh "ln -s #{root_path}/launch4j/bin-#{prefix} #{root_path}/launch4j/bin"
      end
    end

    def deploy(options)
      @project_name = options.project_name
      @classpath = options.classpath
      @main_java_class = options.main_java_file
      @built_jar_path = options.jar_output_dir

      @java_app_deploy_path = options.windows_output_dir
      @target_jvm_version = options.target_jvm_version
      @minimum_windows_jvm_version = options.minimum_windows_jvm_version
      @jvm_arguments = options.jvm_arguments
      @java_library_path = options.java_library_path

      @startup_error_message     = options.windows_startup_error_message
      @bundled_jre_error_message = options.windows_bundled_jre_error_message
      @jre_version_error_message = options.windows_jre_version_error_message
      @launcher_error_message    = options.windows_launcher_error_message
      @icon_path                 = options.windows_icon_path
      @executable_type           = options.executable_type
      
      @launch4j_config_file = "#{@java_app_deploy_path}/configuration.xml"

      copy_deployment_to @java_app_deploy_path
      puts "Creating Windows application in #{@built_jar_path}/#{@project_name}.exe"

      
      File.open(@launch4j_config_file, 'w') do |file|
        file << BundlerTemplate.find('exe_bundler', 'configuration.xml').result(binding)
      end

      file_dir_name = File.dirname(__FILE__)

      # Set ACL permissions to allow launch4j bundler to run on Windows
      if Platform.instance.using_windows?
        # Check for FAT32 vs NTFS, the cacls command doesn't work on FAT32 nor is it required
        volume = file_dir_name.split(":").first.upcase + ':'
        output = `fsutil fsinfo ntfsinfo #{volume}`
        # fsutil can only work with admin priviledges
        raise output if output =~ /requires that you have administrative privileges/
        raise output if output =~ /Error:/
        if 'NTFS' == output.split("\n")[0][0..3]
          sh "echo y | cacls \"#{file_dir_name}/launch4j/bin-win/windres.exe\" /G \"#{ENV['USERNAME']}\":F"
          sh "echo y | cacls \"#{file_dir_name}/launch4j/bin-win/ld.exe\" /G \"#{ENV['USERNAME']}\":F"
        end
        link_launch4j_bin('win', file_dir_name)
      elsif Platform.instance.using_linux?
        link_launch4j_bin('linux', file_dir_name)
      elsif Platform.instance.using_mac?
        link_launch4j_bin('mac', file_dir_name)
      end

      cmd = "java -jar \"#{file_dir_name}/launch4j/launch4j.jar\" \"#{@launch4j_config_file}\""
      warn "call: #{cmd}"
      sh cmd 
    end

  end
end
