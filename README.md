Rawr 1.4.0
==========

James Britt, Logan Barnett, David Koontz

http://github.com/rawr/rawr


DESCRIPTION
-----------
  
Rawr is a packaging solution for JRuby applications. Rawr comes in two
pieces:

* a `rawr` command that creates a Java _main_ file in your application
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

* JRuby >= 1.4
* javac
* Rake

INSTALL
-------

    sudo gem install rawr

LICENSE
-------

Rawr is released under the Ruby License.
