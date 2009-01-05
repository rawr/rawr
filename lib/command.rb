module Rawr
  class Command
    def self.fetch_jruby(args=ARGV)
      until args.empty?
        arg = args.shift
        case arg
        when '--fetch-version'
          version = args.shift
        when '--destination'
          destination = args.shift
        end
      end

      version ||= 'current'
      destination ||= './lib/java'

      require 'jruby_release'
      JRubyRelease.get version, destination
    end
  end
end