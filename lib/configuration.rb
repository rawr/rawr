module Rawr
  class Configuration
    def self.guess_project_name
      return File.basename(Dir.pwd)
    end
  end
end
