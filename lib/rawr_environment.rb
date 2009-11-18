module Rawr
  def ruby_environment
    env_pieces = RUBY_DESCRIPTION.match(/^(.*?\)) .*?(\[.*?\])/)
    return env_pieces[1..2].join(' ')
  end
  module_function :ruby_environment
  
  def ensure_jruby_environment
    begin
      include Java
    rescue NameError
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
