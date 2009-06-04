module Rawr
  def ensure_jruby_environment
    begin
      require 'java'
    rescue LoadError
      warn <<-ERROR
Rawr will only work from JRuby.
First, remove the Rawr gem in your other environment to prevent conflicts:

  gem uninstall rawr

Second, install this gem in your JRuby environment with the following command:

  jruby -S gem install rawr

  ERROR

      exit
    end
  end
  module_function :ensure_jruby_environment
end