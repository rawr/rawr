module Rawr
  class JarBuilder
    attr_accessor :target_in_jar

    def initialize(name, directory, items, exclusion = nil)
      @name = name
      @directory = directory
      @items = items
      @exclusion = exclusion
    end

    def build
      if (@items.kind_of? Array) && !@items.empty?
        dir_string = " -C #{@directory} #{@items.join(' ')}"
      elsif @items.kind_of? String
        dir_string = " -C #{@directory} #{@items}"
      else
        dir_string = " -C #{@directory} ."
      end
      jar_command = "jar cfM \"#{Rawr::Options.data.jar_output_dir}/#{@name}\" #{dir_string}"
      puts "Building Jar file #{@name} in #{Rawr::Options.data.jar_output_dir}"
      sh jar_command
    end
  end
end