module Rawr
  class Rawr

# Is there anything the user *must* provide for config state?
    REQUIRED_VALUES_ERROR_MSGS = {
      #:project_name => "Missing project name.",
      #:base_package => "Missing base package name.",
      #:target =>  "Missing target."
    }


    REQUIRED_VALUES_EXCLUSIONS = [ ]

    def self.errors
      @@errors ||= []
    end

    def self.valid_options?  options_hash
      @@errors = []
      options_hash.keys.each do |k|
        return true if REQUIRED_VALUES_EXCLUSIONS.include?(k)   
      end

      REQUIRED_VALUES_ERROR_MSGS.each do |val, msg|
        @@errors << msg unless options_hash[val]
      end

      @@errors.empty? 
    end


    def self.project options_hash
      @@current_options = options_hash

      puts "HAVE @@current_options = \n#{@@current_options.pretty_inspect}"
    end
  end
end
