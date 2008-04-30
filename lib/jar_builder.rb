class JarBuilder
  attr_accessor :name, :globs, :dirs
  
  def initialize
    @globs = []
    @dirs = []
  end
  
  def build
    jar_command = "jar cfM \"#{Rawr::Options[:package_dir]}/#{name}\" ."
    sh jar_command
  end
end