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
      File.open(shell_file_name,'w') do |f|
        f << <<-ENDL
#! /bin/sh
java -jar #{project_name}.jar
ENDL
      end
      chmod 0755, shell_file_name
    end
  end
end