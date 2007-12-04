# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'lib/rawr_version'

Hoe.new('rawr', Rawr::VERSION) do |p|
  p.rubyforge_name = 'rawr'
  p.author = 'David Koontz'
  p.email = 'david@koontzfamily.org'
  p.summary = 'Easy packaging for JRuby applications'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

# vim: syntax=Ruby
