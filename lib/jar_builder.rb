module Rawr
  class JarBuilder
    attr_accessor :name, :globs, :dirs

    def initialize
      @globs = []
      @dirs = []
    end

    def build
      dir_strings = @dirs.map {|dir| " -C #{dir} "}
      jar_command = "jar cfM \"#{Rawr::Options[:base_dir]}/#{name}\" #{dir_strings} ."
      sh jar_command
    end
  end
end