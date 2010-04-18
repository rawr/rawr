require 'rawr_environment'
puts "\n#{'-'*80}\nRunning in #{Rawr::ruby_environment}\n#{'-'*80}\n"

require 'fileutils'

require 'core_ext'
require 'platform'
require 'configuration'
require 'creator'
require 'jar_builder'

def file_is_newer?(source, target)
  !File.exists?(target) || (File.mtime(target) < File.mtime(source))
end

specified_config_file = false
if Object.constants.include?('RAWR_CONFIG_FILE')
  # RAWR_CONFIG_FILE can be set in the project's Rakefile
  specified_config_file = true
else
  if ENV.include?('RAWR_CONFIG_FILE')
    RAWR_CONFIG_FILE = ENV["RAWR_CONFIG_FILE"]
    specified_config_file = true
  else
    RAWR_CONFIG_FILE = 'build_configuration.rb'
  end
end

CONFIG = Rawr::Configuration.default
if File.exist?(RAWR_CONFIG_FILE)
  CONFIG.load_from_file!(RAWR_CONFIG_FILE)
elsif specified_config_file
  raise "Rawr configuration file \"#{RAWR_CONFIG_FILE}\" does not exist."
end

namespace :rawr do
  
  PACKAGED_EXTRA_USER_JARS = FileList.new
  extra_user_jars_list = CONFIG.extra_user_jars
  extra_user_jars_list.each { |jar_nick, jar_settings|
    jar_file_path = File.join(CONFIG.jar_output_dir, jar_nick.to_s + '.jar')
    
    PACKAGED_EXTRA_USER_JARS.add(jar_file_path)
    
    jar_builder = Rawr::JarBuilder.new(jar_nick, jar_file_path, jar_settings)
    jar_builders ||= Hash.new
    jar_builders[jar_nick] = jar_builder
    files_to_add = FileList[jar_builder.files_to_add].pathmap(File.join(jar_builder.directory, '%p'))
    
    file jar_file_path => CONFIG.jar_output_dir
    file jar_file_path => files_to_add do
      jar_builders[jar_nick].build
    end
  }
  
  desc "Build all additional user jars"
  task :build_extra_jars => PACKAGED_EXTRA_USER_JARS
  
  desc "Removes generated content"
  task :clean do
    FileUtils.remove_dir(CONFIG.output_dir) if File.directory? CONFIG.output_dir
  end
  
  directory CONFIG.compile_dir
  directory CONFIG.compiled_java_classes_path
  directory CONFIG.compiled_ruby_files_path
  directory CONFIG.compiled_non_source_files_path
  
  directory CONFIG.meta_inf_dir
  
  directory CONFIG.jar_output_dir
  
  COMPILED_JAVA_CLASSES = FileList.new
  java_source_file_list = CONFIG.java_source_files
  java_source_file_list.each { |file_info|
    delimiter = Platform.instance.argument_delimiter
    file_name = file_info.filename
    directory = file_info.directory
    source_file = File.join(directory, file_name)
    target_file = File.join(CONFIG.compiled_java_classes_path, file_name.pathmap('%X.class'))
    COMPILED_JAVA_CLASSES.add(target_file)
    
    target_jvm_version = [ '-target', CONFIG.target_jvm_version.to_s ]
    classpath = ['-cp', (CONFIG.classpath + CONFIG.source_dirs).join(delimiter) ]
    sourcepath = [ '-sourcepath', CONFIG.source_dirs.join(delimiter) ]
    outdir = [ '-d', CONFIG.compiled_java_classes_path ]
    base_javac_args = target_jvm_version + classpath + sourcepath + outdir
    
    file target_file => [ source_file, CONFIG.compiled_java_classes_path ] do
      sh 'javac', *(base_javac_args + [source_file])
    end
  }
  
  COMPILED_RUBY_CLASSES = FileList.new
  ruby_source_file_list = CONFIG.ruby_source_files
  ruby_source_file_list.each { |file_info|
    orig_file_path = File.join(file_info.directory, file_info.filename)
    dest_file_path = File.join(CONFIG.compiled_ruby_files_path, file_info.filename.pathmap('%X.class'))
    dest_dir = File.dirname(dest_file_path)
    
    COMPILED_RUBY_CLASSES.add(dest_file_path)
    
    directory dest_dir
    file dest_file_path => [ orig_file_path, dest_dir ] do
      puts "Compile #{orig_file_path} into #{dest_file_path}"
      require 'command'
      Rawr::Command.compile_ruby_dirs(CONFIG.source_dirs,
                                      CONFIG.compiled_ruby_files_path,
                                      CONFIG.jruby_jar,
                                      CONFIG.source_exclude_filter,
                                      CONFIG.target_jvm_version,
                                      !CONFIG.compile_ruby_files)
    end
  }
  
  COPIED_NON_SOURCE_FILES = FileList.new
  non_source_file_list = CONFIG.non_source_file_list
  non_source_file_list.each { |file_info|
    orig_file_path = File.join(file_info.directory, file_info.filename)
    dest_file_path = File.join(CONFIG.compiled_ruby_files_path, file_info.filename)
    dest_dir = File.dirname(dest_file_path)
    
    COPIED_NON_SOURCE_FILES.add(dest_file_path)
    
    directory dest_dir
    
    file dest_file_path => [ orig_file_path, dest_dir ] do
      puts "Copying non-source file #{orig_file_path} to #{dest_file_path}"
      copy orig_file_path, dest_file_path
    end
  }
  
  desc 'Compiles all the Java source and Ruby source files in the source_dirs entry in the build_configuration.rb file.'
  task :compile => COMPILED_JAVA_CLASSES
  task :compile => COMPILED_RUBY_CLASSES
  task :compile => COPIED_NON_SOURCE_FILES
  
  desc "Compiles the Java source files specified in the source_dirs entry"
  task :compile_java_classes => COMPILED_JAVA_CLASSES
  
  desc "Compiles the Ruby source files specified in the source_dirs entry"
  task :compile_ruby_classes => COMPILED_RUBY_CLASSES

  desc "Compiles the Duby source files specified in the source_dirs entry"
  task :compile_duby_classes => [ CONFIG.compile_dir ] do
    duby_source_file_list = CONFIG.source_dirs.find_files_and_filter('*.duby', CONFIG.source_exclude_filter)
    duby_source_file_list.each do |file_info|
      filename = file_info.filename
      directory = file_info.directory
      
      relative_dir, name = File.split(filename)
      
      if name[0..0] =~ /\d/
        processed_file = relative_dir + '/$' + name
      else
        processed_file = filename
      end
      
      processed_file = processed_file.sub(/\.duby$/, '.class')
      target_file = "#{CONFIG.compile_dir}/#{processed_file}"
      
      if file_is_newer?("#{directory}/#{filename}", target_file)
        FileUtils.mkdir_p(File.dirname("#{CONFIG.compile_dir}/#{processed_file}"))
        
        sh "dubyc -J-classpath #{directory}/#{filename}"
        File.move("#{directory}/#{processed_file}", "#{CONFIG.compile_dir}/#{processed_file}")
      end
    end
  end
  
  task :copy_other_file_in_source_dirs => COPIED_NON_SOURCE_FILES
  
  file CONFIG.base_jar_complete_path => "rawr:compile"
  file CONFIG.base_jar_complete_path => CONFIG.meta_inf_dir
  file CONFIG.base_jar_complete_path => CONFIG.jar_output_dir do
    Rawr::Creator.create_manifest_file(CONFIG)
    Rawr::Creator.create_run_config_file(CONFIG)
    root_as_base = proc do |path| path.sub(/^(java|ruby|non-source)./, '') end
    builder = Rawr::JarBuilder.new(CONFIG.project_name,
                                   CONFIG.base_jar_complete_path,
                                   {:directory => CONFIG.compile_dir,
                                    :dir_mapping => root_as_base})
    builder.build
  end
  
  desc "Create a base jar file"
  task :base_jar => CONFIG.base_jar_complete_path
  
  desc "Uses compiled output and creates an executable jar file."
  task :jar => CONFIG.base_jar_complete_path
  task :jar => PACKAGED_EXTRA_USER_JARS
  task :jar do
    (CONFIG.classpath + CONFIG.files_to_copy).each do |file|
      destination_file = file.gsub('../', '')
      destination_file_path = File.join(CONFIG.jar_output_dir, destination_file)
      FileUtils.mkdir_p(File.dirname(destination_file_path))
      copy file, destination_file_path
    end
  end
  
  directory CONFIG.windows_output_dir
  directory CONFIG.osx_output_dir
  
  namespace :bundle do
    desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
    task :app => [ "rawr:jar", CONFIG.osx_output_dir ] do
      require 'app_bundler'
      Rawr::AppBundler.new.deploy CONFIG
    end

    desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
    task :exe => [ "rawr:jar", CONFIG.windows_output_dir ] do
      require 'exe_bundler'
      Rawr::ExeBundler.new.deploy CONFIG
    end
  end

  namespace :get do
    desc "Fetch the most recent stable jruby-complete.jar"
    task 'current-stable-jruby' do
      require 'jruby_release'
      #TODO: jruby-complete location should be formally recognized by config
      Rawr::JRubyRelease.get 'stable', 'lib/java'
    end

    desc "Fetch the most recent build of  jruby-complete.jar. Might be an RC"
    task 'current-jruby' do
      require 'jruby_release'
      #TODO: jruby-complete location should be formally recognized by config
      Rawr::JRubyRelease.get 'current', 'lib/java'
    end
  end
end
