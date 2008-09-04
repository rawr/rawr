# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'rawr_version'

PROJ.name = 'rawr'
PROJ.authors = 'David Koontz, Logan Barnett, James Britt'
PROJ.email = 'david@koontzfamily.org'
PROJ.url = 'http://rubyforge.org/projects/rawr/'
PROJ.version = Rawr::VERSION
PROJ.summary = "Rawr is a packaging and deployment solution for JRuby applications."
PROJ.rubyforge.name = 'rawr'
PROJ.spec.files = FileList['test/**/*_spec.rb'],
PROJ.spec.opts << '--color'
PROJ.spec.libs << 'test/unit'
PROJ.ruby_opts = []
PROJ.libs << File.expand_path(File.dirname(__FILE__) + "/lib")

task :default => 'spec'

task :update_version_readme do
  readme = IO.readlines( 'README.txt')
  File.open( 'README.txt', 'w' ) { |f| 
    f << "Rawr #{Rawr::VERSION}\n"
    readme.shift
    f << readme
  }
end

task 'gem:package' => [:update_version_readme]

#require 'rubygems'
#require 'hoe'
#require 'lib/rawr_version'
#require 'spec/rake/spectask'
#
#Hoe.new('rawr', Rawr::VERSION) do |p|
#  p.rubyforge_name = 'rawr'
#  p.author = 'David Koontz'
#  p.email = 'david@koontzfamily.org'
#  p.summary = 'Easy packaging for JRuby applications'
#  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
#  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
#  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
#end
#
#namespace :test do
#  desc "Run all spec tests"
#  Spec::Rake::SpecTask.new(:unit) do |t|
#    t.libs << ["lib", "bin", 'test/unit']
#    t.pattern = 'test/unit/*_spec.rb'
#    #t.spec_opts = ["-f s"]
#    t.spec_opts = ['--color']
#  end
#end