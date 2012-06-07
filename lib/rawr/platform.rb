require 'rbconfig'
require 'singleton'

class Platform
  include Singleton
  
  @@operating_system = RbConfig::CONFIG['host_os']
  
  def using_unix?
    @using_unix ||= !using_windows?
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
    using_windows? ? ';' : ':'
  end
end