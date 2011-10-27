# -*- coding: UTF-8 -*-

namespace :packager do
  task :setup do
    dir = File.expand_path("#{File.dirname(__FILE__)}/../")
    require "#{dir}/packager"
  end

  desc 'Clean vendor gems'
  task :cleanup => :setup do
    Packager.cleanup!
  end

  namespace :debian do
    desc 'Build package for debian based linux'
    task :prepare => "packager:setup" do
      Packager.prepare_debian_package!
    end

    desc 'Create the package itself'
    task :create => :prepare do
      Packager.create_debian_package!
    end

  end
end
