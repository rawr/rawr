require 'fileutils'
require 'bundler'
require 'platform'

module Rawr
  class ShellBundler < Bundler
    include FileUtils


    def deploy(options)
      @options = options
      mkdir_p @options.shell_output_dir
      cd @options.shell_output_dir do
        copy_deployment_to '.'
        create_shell_file @options.project_name
      end
    end

    def create_shell_file(project_name)
      shell_file_name = project_name + '.sh'
      File.open(shell_file_name, 'w') do |f|
        f << <<-ENDL
#! /bin/sh
java #{jvm_arguments} #{native_library_path} -jar #{project_name}.jar
ENDL
      end
      chmod 0755, File.expand_path(shell_file_name)
    end

    def jvm_arguments
      ''
    end

    def native_library_path
      if false
        "-Djava.library.path=#{path}"
      else
        ''
      end
    end
  end
end