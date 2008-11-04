require 'rbconfig'
require 'singleton'

class Platform
  include Singleton
  
  @@operating_system = Config::CONFIG['host_os']
  
  def using_unix?
    # HOME is a known Cygwin environment variable. If other Unix-on-Windows
    # variations need anything else, check for them here
    @using_unix ||= (!using_windows? && (ENV["HOME"].nil? || ENV["HOME"].empty?))
  end
  
  def using_windows?
    @using_windows ||= (@@operating_system =~ /^win|mswin/i)
  end
  
  def using_linux?
    @using_linux ||= (@@operating_system =~ /linux/)
  end
  
  def using_mac?
    @using_mac ||= (@@operating_system =~ /darwin/)
  end
  
  def argument_delimiter
    using_unix? ? ':' : ';'
  end
end