namespace "rawr:bundle" do

  desc "Bundles the jar from rawr:jar into a native Mac OS X application (.app)"
  task :app => ["rawr:jar"] do
    require 'rawr/app_bundler'
    Rawr::AppBundler.new.deploy Rawr::Configuration.current_config
  end

  desc "Bundles the jar from rawr:jar into a native Windows application (.exe)"
  task :exe => ["rawr:jar"] do
    require 'rawr/exe_bundler'
    Rawr::ExeBundler.new.deploy Rawr::Configuration.current_config
  end
  
  desc "Bundles the jar from rawr:jar into a Java Web Start application (.jnlp)"
  task :web => ["rawr:jar"] do
    require 'rawr/web_bundler'
    Rawr::WebBundler.new.deploy Rawr::Configuration.current_config
  end
end


