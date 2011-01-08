module Rawr
  # Returns a short human-readable description of the interpreter on
  # which Rawr is running.
  # 
  # @example Output on MRI 1.8.7
  #   "ruby 1.8.7 (2009-06-12 patchlevel 174) [x86_64-linux]"
  # 
  # @example Output on JRuby 1.4
  #   "jruby 1.4.0 (ruby 1.8.7 patchlevel 174) [amd64-java]"
  # 
  # @return [String] a short description of the current Ruby interpreter
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
