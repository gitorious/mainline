#--
#   Copyright (C) 2012-2013 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

namespace :backup do

  # Full backup snapshot/restore for reasonably standard Gitorious
  # setups. Saves/restores the state of the Gitorious installation
  # to/from a single tarball. Also saves the local Gitorious config
  # files, easying the reinstall process if the entire installation is
  # lost.

  # Use for backup/disaster recovery, for cloning/migrating to a new
  # server, or simply for quick snapshotting/restoring during
  # testing/development/experimentation.

  # Backup/disaster recovery:
  # Perform regular, timestamped runs of the backup:snapshot task.
  # If your data is corrupted/lost, run backup:restore in the root
  # directory. If the entire Gitorious installation is lost, reinstall
  # a new working Gitorious server, then run backup:restore there, possibly
  # including the old config files (RESTORE_CONFIG_FILES=true).

  # OPTIONS:
  #
  # Options are passed to the rake task with env variables.
  #
  # RAILS_ENV=<production|development|test|staging..>
  #
  # TARBALL_PATH=<PATH> Specify path of tar file to backup to/restore
  # from.
  #
  # RESTORE_CONFIG_FILES=true During restore, overwrite config files
  # of current Gitorious install with previously backed up config
  # files (config/{database,gitorious,authentication}.yml) plus the
  # custom hooks (data/hooks/custom-{post-receive,pre-receive,update})
  #
  # SKIP_REPOS=true Don't include the hosted repositories in
  # snapshot. Useful for large installations where size of hosted git
  # repos are big enough to make tarballing it all non-viable, and in
  # these cases you'll need to perform cp/rsync etc yourself
  # instead. Note: if you skip the repos during snapshot/restore, the
  # scripts will simply output some suggestions on where to find/place
  # the repositories yourself.

  # EXAMPLES:
  #
  # Simple dump of production env to default tarball file in current directory:
  # bundle exec rake backup:snapshot RAILS_ENV=production
  #
  # Simple restore of production env from default tarball in current directory:
  # bundle exec rake backup:restore RAILS_ENV=production
  #
  # More explicit: specify tarball path
  # bundle exec rake backup:snapshot RAILS_ENV=production TARBALL_PATH="current_snapshot.tar"
  # bundle exec rake backup:restore RAILS_ENV=production TARBALL_PATH="current_snapshot.tar"
  #
  # During restore of a snapshot, also restore config files
  # bundle exec rake backup:snapshot RAILS_ENV=production RESTORE_CONFIG_FILES=true

  # Do the actual git repo backup/restore separately yourself
  # bundle exec rake backup:snapshot RAILS_ENV=production SKIP_REPOS=true
  # bundle exec rake backup:restore RAILS_ENV=production SKIP_REPOS=true

  # ASSUMPTIONS:

  # 0. Both backup and restore tasks must be started from within the
  # root of your Gitorious installation. For disaster recovery, you'll
  # first need to get a functional installation of Gitorious up, after which
  # you can run the recover task to bring in the data and possibly
  # configuration files from a a snapshot tarball.

  # 1. You need to specify which environment you
  # snapshotting/restoring (production, development, etc). See example
  # above to pass this as param.

  # 2. Leans on the 'mysqldump' util for database backup.

  # 3. Doesn't currently capture queue state, so you may want to shut
  # down the web frontend first and let the queues settle down before
  # using these snapshot/restore operations in production systems.

  # 4. Assumes that you have the time and disk-space to slurp down all
  # repos into a local tarball. Sites with huge amounts of repo data
  # may need custom backup schemes. For large sites consider using the
  # SKIP_REPOS=true option and copying the repos as a separate,
  # explicit step.

  # 5. The restore step (especially if restoring old config files)
  # assumes only minor changes in versions of Gitorious between
  # snapshot and subsequent restoration of a backup. Major version
  # jumps may necessitate a more manual restore procedure due to
  # changes in configurations, db schema, folder structure etc.

  DEFAULT_TAR_PATH="snapshot.tar"
  SQL_DUMP_FILE="db_state.sql"
  TMP_WORKDIR="tmp-backup-workdir"
  RAILS_ENV = ENV["RAILS_ENV"]

  def db_config
    require "gitorious/configuration_reader"
    @db_config ||= Gitorious::ConfigurationReader.read('config/database.yml')
  end

  def repo_path
    RepositoryRoot.default_base_path
  end

  def db_name
    db_config[RAILS_ENV]['database']
  end

  def database_credential_options
    db = db_config[RAILS_ENV]
    params = {u: 'username', p: 'password', h: 'host', P: 'port'}

    params.map {|o,k| "-#{o}#{db[k]}" if db[k]}.join(' ')
  end

  def restore_config_files?
    (ENV["RESTORE_CONFIG_FILES"] == "true")
  end

  def skip_repos?
    (ENV["SKIP_REPOS"] == "true")
  end

  def tarball_path
    ENV["TARBALL_PATH"] || DEFAULT_TAR_PATH
  end

  def cleanup
    puts "Cleaning up..."
    puts `rm -rf #{SQL_DUMP_FILE};rm -rf #{TMP_WORKDIR}`
  end

  desc "Simple state snapshot of the Gitorious instance to a single tarball."
  task :snapshot => :environment do
    puts "Initializing..."
    puts `rm -f #{tarball_path};rm -f #{SQL_DUMP_FILE}`
    puts `rm -rf #{TMP_WORKDIR}; mkdir #{TMP_WORKDIR}`

    puts `mkdir #{TMP_WORKDIR}/config`
    puts `mkdir -p #{TMP_WORKDIR}/data/hooks`

    if skip_repos?
      puts "=================================================================="
      puts "NOTE: Not including the actual git repositories in this snapshot."
      puts "You'll need to backup the hosted repo data manually from '#{repo_path}'"
      puts "=================================================================="
    else
      puts "Backing up repositories in #{repo_path}..."
      puts `mkdir #{TMP_WORKDIR}/repos`
      puts `cp -r #{repo_path}/* #{TMP_WORKDIR}/repos`
    end

    puts "Backing up custom config files..."
    puts `cp ./config/gitorious.yml #{TMP_WORKDIR}/config`
    puts `cp ./config/database.yml #{TMP_WORKDIR}/config`

    if File.exist?("./config/authentication.yml")
      puts `cp ./config/authentication.yml #{TMP_WORKDIR}/config`
    end

    puts "Backing up uploaded assets (avatar pictures etc)"
    if File.exist?("./public/system")
      puts `cp -r ./public/system #{TMP_WORKDIR}/public_system_uploaded_assets`
    end

    puts "Backing up custom hooks..."
    if File.exist?("./data/hooks/custom-pre-receive")
      puts `cp ./data/hooks/custom-pre-receive #{TMP_WORKDIR}/data/hooks`
    end
    if File.exist?("./data/hooks/custom-post-receive")
      puts `cp ./data/hooks/custom-post-receive #{TMP_WORKDIR}/data/hooks`
    end
    if File.exist?("./data/hooks/custom-update")
      puts `cp ./data/hooks/custom-update #{TMP_WORKDIR}/data/hooks`
    end

    puts "Backing up mysql state..."
    puts `mysqldump #{database_credential_options} #{db_name} > #{TMP_WORKDIR}/#{SQL_DUMP_FILE}`

    puts "Archiving it all in #{tarball_path}..."
    puts `tar -czf #{tarball_path} #{TMP_WORKDIR}`

    cleanup

    puts "Done! Backed up current Gitorious state to #{tarball_path}."
  end

  desc "Restores Gitorious instance to snapshot previously stored in tarball file."
  task :restore => [:environment, "db:drop", "db:create"] do
    abort "Snapshot file #{tarball_path} not found, aborting" unless File.exist?(tarball_path)
    abort "Repo dir #{repo_path.to_s} not found in current Gitorous installation, aborting" unless File.exist?(repo_path.to_s)

    puts "Preparing..."
    puts `rm -rf #{TMP_WORKDIR};tar -xf #{tarball_path}`

    if skip_repos?
      puts "=================================================================="
      puts "NOTE: Skipping repos, not restoring the actual git repositories."
      puts "To do so manually you'll need to a backed up copy of your repositories into '#{repo_path}' yourself."
      puts "=================================================================="
    else
      if !File.exist?("#{TMP_WORKDIR}/repos")
        puts "=================================================================="
        puts "No repostories present in snapshot, aborting."
        puts "Perhaps the repositories skipped during when the snapshot was created?"
        puts "If so then run the restore command with 'SKIP_REPOS=true' env variable as well, eg 'env SKIP_REPOS=true bin/restore ...'"
        puts "=================================================================="
        cleanup
        exit
      end
      puts "Restoring repositories in #{repo_path}..."
      puts `mkdir -p #{repo_path}`
      puts `cp -rf #{TMP_WORKDIR}/repos/* #{repo_path}`
    end

    if restore_config_files?
      puts "Restoring custom config files..."
      puts `cp -f #{TMP_WORKDIR}/config/* ./config`

      puts "Restoring custom hooks..."
      puts `cp -f #{TMP_WORKDIR}/data/hooks/* ./data/hooks`
    end

    puts "Restoring uploaded assets (avatar pictures etc)"
    if File.exist?("#{TMP_WORKDIR}/public_system_uploaded_assets")
      puts `rm -rf ./public/system`
      puts `cp -rf #{TMP_WORKDIR}/public_system_uploaded_assets ./public/system`
    end

    puts "Restoring mysql state..."
    puts `mysql #{database_credential_options} #{db_name} < #{TMP_WORKDIR}/#{SQL_DUMP_FILE}`

    puts "Upgrading database structure..."
    Rake::Task["db:migrate"].invoke

    puts "Rebuilding ~/.ssh/authorized_keys from user keys in database..."
    puts `bundle exec script/regenerate_ssh_keys`

    puts "Recreating symlink to common hooks"
    puts `rm -f #{repo_path}/.hooks`
    puts `ln -s #{File.expand_path('./data/hooks')} #{repo_path}/.hooks`

    puts "Regenerating Sphinx indexes"
    Rake::Task["ts:rebuild"].invoke

    cleanup

    puts "Done restoring Gitorious from #{tarball_path}."
  end
end
