module Packager
  extend self

  DEBIAN_PATH = 'debian/tmp/var/www/gitorious'
  DEBIAN_FILES = %w(app AUTHORS bin config data db doc HACKING Gemfile Gemfile.lock lib LICENSE log public Rakefile README script test tmp TODO.txt vendor)

  def cleanup!
    %w[vendor/bundle lib/bundler].each do |dir|
      dir = Rails.root.join(dir)
      FileUtils.rm_rf(dir) if File.directory?(dir)
    end
  end

  def prepare_debian_package!
    [Packager::DEBIAN_PATH, "tmp", "log"].each do |dir|
      dir = Rails.root.join(dir)
      FileUtils.mkdir_p(dir)
    end

    FileUtils.cp_r(Packager::DEBIAN_FILES, Packager::DEBIAN_PATH)
  end

  def create_debian_package!
    system("dpkg-buildpackage -rfakeroot")
  end

end
