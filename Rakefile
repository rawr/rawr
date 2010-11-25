require 'rake'

#gem 'rdoc'
#require 'rdoc'

#load 'tasks/setup.rb'

begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'rawr_version'

Bones {

name  'rawr'
authors  'James Britt, Logan Barnett, David Koontz'
email  'james@neurogami.com'
url  'http://github.com/rawr/rawr'
version  Rawr::VERSION
readme_file  'README.md'
summary  "Rawr is a packaging and deployment solution for JRuby applications."
rdoc_exclude  %w(launch4j)
ruby_opts  []
libs << 'lib'
gem.dependencies  %w{ user-choices rubyzip }
gem.platform  "java"
gem.need_tar false
gem.need_zip false

}

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

require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('specs:run') do |t|
  t.spec_files = FileList['test/**/*_spec.rb']
end

