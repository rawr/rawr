require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'rawr/jar_builder'

require 'rubygems'
require 'rake'
require 'fileutils'
require 'rawr/core_ext'



describe Rawr::JarBuilder do
  before :each do
    @spec_jar_name = 'SPECJAR.jar'
    @jar_file_path = File.join(File.expand_path(File.dirname(__FILE__)), @spec_jar_name)

    if File.exist? @jar_file_path 
      FileUtils.rm @jar_file_path 
    end
  end


  #after :each do
  #  @jar_file_path = File.join(File.expand_path(File.dirname(__FILE__)), @spec_jar_name)

  #  if File.exist? @jar_file_path 
  #    FileUtils.rm @jar_file_path 
  #  end
  #end

  #  it "passes the globs to the jar command on build"

  it "takes the list of files and inserts all directories of those file paths" do

    files = %w{ foo/bar/baz  foo/bar/biff blub/bloop }
    class Z
      include Rawr::FileHelpers
    end

    Z.new.add_dirs  files
    files.size.should == 6

  end

  it "builds jars that contain directory entries" do

    jar_nick = 'specjar'
    test_root_dir = File.join(File.expand_path(File.dirname(__FILE__)), '..')

    jar_settings = { :directory => test_root_dir }

    jar_builder = Rawr::JarBuilder.new(jar_nick, @jar_file_path, jar_settings)
    jar_builders = {}
    jar_builders[jar_nick] = jar_builder
    files_to_add = FileList[jar_builder.files_to_add].pathmap(File.join(jar_builder.directory, '%p'))


    res = jar_builders[jar_nick].build
    res.include?('unit').should == true
    res.sort.should == ["spec_helpers.rb", "unit", "unit/app_bundler_spec.rb", "unit/bundler_spec.rb", "unit/creator_spec.rb", "unit/jar_builder_spec.rb", "unit/kde_bundler_spec.rb", "unit/options_spec.rb", "unit/platform_spec.rb", "unit/shell_bundler_spec.rb", "unit/web_bundler_spec.rb"] 
  end
end
