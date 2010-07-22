# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.
require 'rubygems'
gem 'rdoc'
require 'rdoc'

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'rawr_version'

PROJ.name = 'rawr'
PROJ.authors = 'James Britt, Logan Barnett, David Koontz'
PROJ.email = 'james@neurogami.com'
PROJ.url = 'http://github.com/rawr/rawr'
PROJ.version = Rawr::VERSION
PROJ.summary = "Rawr is a packaging and deployment solution for JRuby applications."
PROJ.rubyforge.name = 'rawr'
PROJ.spec.files = FileList['test/**/*_spec.rb'],
PROJ.spec.opts << '--color'
PROJ.spec.libs << 'test/unit'
PROJ.rdoc.exclude = %w(launch4j)
PROJ.ruby_opts = []
PROJ.libs << 'lib'
PROJ.gem.dependencies = %w{ user-choices rubyzip }
PROJ.gem.platform = "java"

task :default => 'spec'

task :update_version_readme do
  readme = IO.readlines( 'README.md')
  File.open( 'README.md', 'w' ) do |f| 
    f.puts "Rawr #{Rawr::VERSION}\n"
    readme.shift
    f.puts readme
  end
end

task 'gem:package' => [:update_version_readme]

