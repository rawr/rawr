require 'rawr_environment'
puts "Running in #{Rawr::ruby_environment}"

require 'fileutils'
require 'core_ext'
require 'rbconfig'
require 'platform'
require 'configuration'
require 'generator'
require 'jar_builder'

def file_is_newer?(source, target)
  !File.exists?(target) || (File.mtime(target) < File.mtime(source))
end

RAWR_CONFIG_FILE = 'build_configuration.rb'
OUTPUT_FILES = Rawr::Configuration.load_from_file(RAWR_CONFIG_FILE)

namespace :rawr do
  
  PACKAGED_EXTRA_USER_JARS = FileList.new
  extra_user_jars_list = OUTPUT_FILES.extra_user_jars
  extra_user_jars_list.each { |jar_nick, jar_settings|
    jar_file_path = File.join(OUTPUT_FILES.jar_output_dir, jar_nick.to_s + '.jar')
    
    PACKAGED_EXTRA_USER_JARS.add(jar_file_path)
    
    jar_builder = Rawr::JarBuilder.new(jar_nick, jar_file_path, jar_settings)
    jar_builders ||= Hash.new
    jar_builders[jar_nick] = jar_builder
    files_to_add = FileList[jar_builder.files_to_add].pathmap(File.join(jar_builder.directory, '%p'))
    
    file jar_file_path => OUTPUT_FILES.jar_output_dir
    file jar_file_path => files_to_add do
      jar_builders[jar_nick].build
    end
  }
  
  desc "Build all additional user jars"
  task :build_extra_jars => PACKAGED_EXTRA_USER_JARS
  
  desc "Removes generated content"
  task :clean do
    FileUtils.remove_dir(OUTPUT_FILES.output_dir) if File.directory? OUTPUT_FILES.output_dir
  end
  
  directory OUTPUT_FILES.compile_dir
  
  directory OUTPUT_FILES.meta_inf_dir
  
  directory OUTPUT_FILES.jar_output_dir
  
  COMPILED_JAVA_CLASSES = FileList.new
  java_source_file_list = OUTPUT_FILES.java_source_files
  java_source_file_list.each { |file_info|
    delimiter = Platform.instance.argument_delimiter
    file_name = file_info.filename
    directory = file_info.directory
    target_file = file_name.pathmap(File.join(OUTPUT_FILES.compile_dir, '%X.class'))
    source_file = File.join(directory, file_name)
    COMPILED_JAVA_CLASSES.add(target_file)
    
    target_jvm_version = [ '-target', OUTPUT_FILES.target_jvm_version.to_s ]
    classpath = ['-cp', (OUTPUT_FILES.classpath + OUTPUT_FILES.source_dirs).join(delimiter) ]
    sourcepath = [ '-sourcepath', OUTPUT_FILES.source_dirs.join(delimiter) ]
    outdir = [ '-d', OUTPUT_FILES.compile_dir ]
    base_javac_args = target_jvm_version + classpath + sourcepath + outdir
    
    file target_file => [ source_file, OUTPUT_FILES.compile_dir ] do
      sh 'javac', *(base_javac_args + [source_file])
    end
  }
  
  COMPILED_RUBY_CLASSES = FileList.new
  ruby_source_file_list = OUTPUT_FILES.ruby_source_files
  ruby_source_file_list.each { |file_info|
    orig_file_path = File.join(file_info.directory, file_info.filename)
    dest_file_path = File.join(OUTPUT_FILES.compile_dir, file_info.filename.pathmap('%X.class'))
    dest_dir = File.dirname(dest_file_path)
    
    COMPILED_RUBY_CLASSES.add(dest_file_path)
    
    directory dest_dir
    file dest_file_path => [ orig_file_path, dest_dir ] do
      puts "Compile #{orig_file_path} into #{dest_file_path}"
      require 'command'
      Rawr::Command.compile_ruby_dirs(OUTPUT_FILES.source_dirs,
                                      OUTPUT_FILES.compile_dir,
                                      OUTPUT_FILES.jruby_jar,
                                      OUTPUT_FILES.source_exclude_filter,
                                      OUTPUT_FILES.target_jvm_version,
                                      !OUTPUT_FILES.compile_ruby_files)
    end
  }
  
  COPIED_NON_SOURCE_FILES = FileList.new
  non_source_file_list = OUTPUT_FILES.non_source_file_list
  non_source_file_list.each { |file_info|
    orig_file_path = File.join(file_info.directory, file_info.filename)
    dest_file_path = File.join(OUTPUT_FILES.compile_dir, file_info.filename)
    dest_dir = File.dirname(dest_file_path)
    
    COPIED_NON_SOURCE_FILES.add(dest_file_path)
    
    directory dest_dir
    
    file dest_file_path => [ orig_file_path, dest_dir ] do
      puts "Copying non-source file #{orig_file_path} to #{dest_file_path}"
      File.copy(orig_file_path, dest_file_path)
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
  task :compile_duby_classes => [ OUTPUT_FILES.compile_dir ] do
    duby_source_file_list = OUTPUT_FILES.source_dirs.find_files_and_filter('*.duby', OUTPUT_FILES.source_exclude_filter)
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
      target_file = "#{OUTPUT_FILES.compile_dir}/#{processed_file}"
      
      if file_is_newer?("#{directory}/#{filename}", target_file)
        FileUtils.mkdir_p(File.dirname("#{OUTPUT_FILES.compile_dir}/#{processed_file}"))
        
        sh "dubyc -J-classpath #{directory}/#{filename}"
        File.move("#{directory}/#{processed_file}", "#{OUTPUT_FILES.compile_dir}/#{processed_file}")
      end
    end
  end
  
  task :copy_other_file_in_source_dirs => COPIED_NON_SOURCE_FILES
  
  file OUTPUT_FILES.base_jar_complete_path => "rawr:compile"
  file OUTPUT_FILES.base_jar_complete_path => OUTPUT_FILES.meta_inf_dir
  file OUTPUT_FILES.base_jar_complete_path => OUTPUT_FILES.jar_output_dir do
    Rawr::Generator.create_manifest_file(OUTPUT_FILES)
    Rawr::Generator.create_run_config_file(OUTPUT_FILES)
    builder = Rawr::JarBuilder.new(OUTPUT_FILES.project_name,
                                   OUTPUT_FILES.base_jar_complete_path,
                                   :directory => OUTPUT_FILES.compile_dir)
    builder.build
    
    # Re-add the manifest file using the jar utility so that it
    # is processed as a manifest file and thus signing will work.
    jar_path = OUTPUT_FILES.base_jar_complete_path
    manifest_path = File.join(OUTPUT_FILES.meta_inf_dir, 'MANIFEST.MF')
    sh 'jar', 'ufm', jar_path, manifest_path
  end
  
  desc "Create a base jar file"
  task :base_jar => OUTPUT_FILES.base_jar_complete_path
  
  desc "Uses compiled output and creates an executable jar file."
  task :jar => PACKAGED_EXTRA_USER_JARS
  task :jar => OUTPUT_FILES.base_jar_complete_path do
    (OUTPUT_FILES.classpath + OUTPUT_FILES.files_to_copy).each do |file|
      destination_file = file.gsub('../', '')
      destination_file_path = File.join(OUTPUT_FILES.jar_output_dir, destination_file)
      FileUtils.mkdir_p(File.dirname(destination_file_path))
      File.copy(file, destination_file_path)
    end
  end
  
  directory OUTPUT_FILES.windows_output_dir
  directory OUTPUT_FILES.osx_output_dir
  
  namespace :bundle do
    desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
    task :app => [ "rawr:jar", OUTPUT_FILES.osx_output_dir ] do
      require 'app_bundler'
      Rawr::AppBundler.new.deploy OUTPUT_FILES
    end

    desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
    task :exe => [ "rawr:jar", OUTPUT_FILES.windows_output_dir ] do
      require 'exe_bundler'
      Rawr::ExeBundler.new.deploy OUTPUT_FILES
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
