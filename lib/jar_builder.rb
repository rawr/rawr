class JarBuilder
  attr_accessor :name, :globs, :dirs
  
  def initialize
    @globs = []
    @dirs = []
  end
end