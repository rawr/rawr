require 'erb'

module Rawr
   class BundlerTemplate < ERB

      def self.find(bundle_type, template_name)
         filename = File.join(File.dirname(__FILE__), 'templates', bundle_type, "#{template_name}.erb")

         new(filename)
      end

      def initialize(filename)
         # As of JRuby 1.6.7 $SAFE is not supported in ERB, but this shouldn't
         # matter anyways since any templates loaded should be trusted.
         #
         # '>' causes ERB to eat newlines on lines which contain only ERB <% %> 
         # tags (for pretty output).  This can probably be improved a bit.
         super(File.read(filename), nil, '>')
      end

      #TODO: consider providing access to configuration here and adding a 
      #      render() function, rather than rendering in the Bundle class

   end
end