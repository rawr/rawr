namespace "rawr:bundle" do

  desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
  task :app => ["rawr:jar"] do
    require 'app_bundler'
    Rawr::AppBundler.new.deploy Rawr::Configuration.current_config
  end

  desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
  task :exe => ["rawr:jar"] do
    require 'exe_bundler'
    Rawr::ExeBundler.new.deploy Rawr::Configuration.current_config
  end
  
  desc "Bundles the jar from rawr:jar into a Java Web Start application (.jnlp)"
  task :web => ["rawr:jar"] do
    require 'web_bundler'
    Rawr::WebBundler.new.deploy Rawr::Configuration.current_config
  end
end


