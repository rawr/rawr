Rawr 1.3.8
    by David Koontz, James Britt, and Logan Barnett
    http://www.rubyforge.org/projects/rawr

== DESCRIPTION:
  
Rawr is a packaging solution for JRuby applications. Rawr comes in two pieces, a
rawr command that creates a Java "main" file in your application and a
configuration file that will be used by Rawr to build the final jar and a rake
file that you can include into your project to do the building of the project.

== SYNOPSIS:

  rawr install
  rake rawr:jar
  java -jar package/jar/your_jar_file.jar

== REQUIREMENTS:

* javac
* jar
* rake

== INSTALL:

* sudo gem install rawr

== LICENSE:

Rawr is released under the Ruby License.