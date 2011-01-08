require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'spec_helpers')
require 'rawr/shell_bundler'

describe "Rawr::ShellBundler" do
  describe ".sh creation" do
    before :all do
      @tmp_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_tmp'))
      @bundler = Rawr::ShellBundler.new
      @basic_options = OpenStruct.new :project_name => 'spec_project',
                                      :classpath => '',
                                      :jvm_arguments => '',
                                      :shell_output_dir => @tmp_dir
      @shell_dir = File.join(@tmp_dir, 'shell')
      FileUtils.mkdir_p @shell_dir
    end

    after :all do
      FileUtils.rm_rf @tmp_dir
    end

    it "creates a <project-name>.sh file" do
      #@bundler.deploy @basic_options
      FileUtils.cd @shell_dir do
        @bundler.create_shell_file 'spec_project'
      end
      File.should be_exist(File.join(@shell_dir, 'spec_project.sh'))
    end
    
    it "creates a .sh file with +x permissions" do
      FileUtils.cd @shell_dir do
        @bundler.create_shell_file 'spec_project'
      end
      File.should be_executable(File.join(@shell_dir, 'spec_project.sh'))
    end
  end
  
  describe ".sh invocation" do
    it "runs the app using java -jar"
    it "passes along the classpath"
    it "passes along jvm arguments"
    it "passes along the java.library.path setting"
  end

  describe ".sh utils" do
    # how does one test this?
    it "Verifies the presense of Java"
    it "Verifies the Java version"
  end
  
  
end