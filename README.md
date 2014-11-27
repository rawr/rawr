Rawr 1.8.0
==========

James Britt, Logan Barnett, David Koontz

http://github.com/rawr/rawr


DESCRIPTION
-----------
  
Rawr is a packaging solution for JRuby applications. Rawr comes in two
pieces:

* a `rawr` command that creates a Java `main` file in your application
and a configuration file that will be used by Rawr to build the final jar;
* a Rake task file that you can include into your project's Rakefile to
automate the creation of the packaged application.

SYNOPSIS
--------

    rawr install
    rake rawr:jar
    java -jar package/jar/your_jar_file.jar

REQUIREMENTS
------------

* JRuby >= 1.7.0
* javac
* Rake

INSTALL
-------

    sudo gem install rawr --source http://gems.neurogami.com

Note: You probably do not want to use `sudo` if you are using a Ruby installed using `rvm`.


STUFF
-----

`Rawr` 1.7.0 has some changes to how the application jar is assembled.  Many versions ago something changed such that when the application jar-building processing was collecting the files indicated by `build_configuration.rb` it was stripping some paths.  For example your project folder might have files in `src/` and `lib/ruby/` but those files would end up in the root of the generated jar.  For assorted reasons this did not seem to break anything, likely because these files were still available via `$:`. But this was just a coincidence.  

Worse, if you had `lib/ruby/foo.rb` and `src/foo.rb` your generated jar file would only get one of them.  This is bad.

Version 1.7.0 changes how such paths are handled and the behavior should be what it was way back in the early days of `Rawr`.

If you find that this new version is breaking your existing applications please report this.  It _shouldn't_ (based on testing) but there may be cases where it does it and it would be good to know why.  If your program breaks with this version it may be that you need to change how to add pats to `$:` or how you reference files when calling `require`.  


`Rawr` 1.6.6 has rb source compilation turned off by default but compilation is working again since `Rawr` 1.6.5, if you want to turn it on in `build_configuration.rb`.

`Rawr` 1.6.0 added support for compiling [Mirah](http://www.mirah.org/) source code.  

There was already code in place for `duby` files, but a) duby morphed in Mirah, and b) the compilation command is somewhat different.

There's a new `build_configuration.rb` option to define the root folder for your Mirah files, and the resulting compiled `.class` files end up where any `.java` files would go.

`Rawr` 1.4.2 introduced the use of Brian Marick's [user-choices](http://user-choices.rubyforge.org/)  library to handle initial configuration properties.

What this means in practice is that there are multiple ways to configure how `rawr` handles the `install` command.

You can use command-line arguments much as before, or use a configuration file (`~/.rawr`), or environment variables.  

Or all of them; you can mix and match.

For example, if you have a preferred name or location for the main Java class then you might want to stick that in the config
file or some environment variables to avoid having to pass them as command-line arguments on each invocation of `rawr`:

    # in ~/.rawr
    local_jruby_jar: /home/james/JRUBY_JARS/1.7.3/jruby-complete.jar
    

Please read the docs for `user-choices`, but one key thing to know is the precedence for options.

- Any option value passed on the command-line overrules any previous value.

- Any option defined in an environment variable overrules the value in a config files.

- Option values in the config file will be used so long as they are not overridden by the above conditions.



LICENSE
-------

Rawr is released under the Ruby License.


Feed your head.
