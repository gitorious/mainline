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

  # EXAMPLES:
  #
  # Simple dump of production env to default tarball file in current directory:
  # sudo bundle exec rake backup:snapshot RAILS_ENV=production
  #
  # Simple restore of production env from default tarball in current directory:
  # sudo bundle exec rake backup:restore RAILS_ENV=production
  #
  # More explicit: specify tarball path
  # sudo bundle exec rake backup:snapshot RAILS_ENV=production TARBALL_PATH="current_snapshot.sql"
  # sudo bundle exec rake backup:restore RAILS_ENV=production TARBALL_PATH="current_snapshot.sql"
  #
  # During restore of a snapshot, also restore config files
  # sudo bundle exec rake backup:snapshot RAILS_ENV=production RESTORE_CONFIG_FILES=true
  
  # ASSUMPTIONS:

  # 0. Both backup and restore tasks must be started from within the
  # root of your Gitorious installation. For disaster recovery, you'll
  # first need to get a functional installation of Gitorious up, after which
  # you can run the recover task to bring in the data and possibly
  # configuration files from a a snapshot tarball.

  # 1. Both tasks should be run as root/superuser to preserve file/dir
  # ownerships and have enough permissions when the backup tasks shell
  # out.

  # 2. You need to specify which environment you
  # snapshotting/restoring (production, development, etc). See example
  # above to pass this as param.

  # 3. Leans on the 'mysqldump' util for database backup.

  # 4. Doesn't currently capture queue state, so you may want to shut
  # down the web frontend first and let the queues settle down before
  # using these snapshot/restore operations in production systems.

  # 5. Assumes that you have the time and disk-space to slurp down all
  # repos into a local tarball. Sites with huge amounts of repo data
  # may need custom backup schemes.

  # 6. The restore step (especially if restoring old config files)
  # assumes only minor changes in versions of Gitorious between
  # snapshot and subsequent restoration of a backup. Major version
  # jumps may necessitate a more manual restore procedure due to
  # changes in configurations, db schema, folder structure etc.
  
  DEFAULT_TAR_PATH="snapshot.tar"
  SQL_DUMP_FILE="db_state.sql"
  TMP_WORKDIR="tmp-backup-workdir"
  RAILS_ENV = ENV["RAILS_ENV"]

  require 'yaml'

  def exit_if_nonsudo
    if Process.uid != 0
      puts "Please run the task as superuser/root!"
      exit
    end
  end
  
  def repo_path
    conf = YAML::load(File.open('config/gitorious.yml'))
    conf[RAILS_ENV]['repository_base_path']
  end

  def db_name
    conf = YAML::load(File.open('config/database.yml'))
    conf[RAILS_ENV]['database']
  end

  def gitorious_user
    conf = YAML::load(File.open('config/gitorious.yml'))
    conf[RAILS_ENV]['gitorious_user']
  end

  def restore_config_files?
    (ENV["RESTORE_CONFIG_FILES"] == "true")
  end
  
  desc "Simple state snapshot of the Gitorious instance to a single tarball."
  task :snapshot do
    exit_if_nonsudo

    tarball_path = ENV["TARBALL_PATH"] || DEFAULT_TAR_PATH

    puts "Initializing..."
    puts `rm -f #{tarball_path};rm -f #{SQL_DUMP_FILE}`
    puts `rm -rf #{TMP_WORKDIR}; mkdir #{TMP_WORKDIR}`
    puts `mkdir #{TMP_WORKDIR}/repos`
    puts `mkdir #{TMP_WORKDIR}/config`
    puts `mkdir -p #{TMP_WORKDIR}/data/hooks`
    
    puts "Backing up custom config files..."
    puts `cp ./config/gitorious.yml #{TMP_WORKDIR}/config`
    puts `cp ./config/database.yml #{TMP_WORKDIR}/config`
    
    if File.exist?("./config/authentication.yml")
      puts `cp ./config/authentication.yml #{TMP_WORKDIR}/config`
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
    puts `mysqldump #{db_name} > #{TMP_WORKDIR}/#{SQL_DUMP_FILE}`
    
    puts "Backing up repositories in #{repo_path}..."
    puts `cp -r #{repo_path}/* #{TMP_WORKDIR}/repos`
    
    puts "Archiving it all in #{tarball_path}..."
    puts `tar -czf #{tarball_path} #{TMP_WORKDIR}`

    puts "Cleaning up..."
    puts `rm -rf #{SQL_DUMP_FILE};rm -rf #{TMP_WORKDIR}`

    puts "Done! Backed up current Gitorious state to #{tarball_path}."
  end

  
  desc "Restores Gitorious instance to snapshot previously stored in tarball file."
  task :restore => ["db:drop", "db:create"] do
    exit_if_nonsudo
    
    tarball_path = ENV["TARBALL_PATH"] || DEFAULT_TAR_PATH

    puts "Preparing..."
    puts `rm -rf #{TMP_WORKDIR};tar -xf #{tarball_path}`

    if restore_config_files?
      puts "Restoring custom config files..."
      puts `cp -f #{TMP_WORKDIR}/config/* ./config`

      puts "Restoring custom hooks..."
      puts `cp -f #{TMP_WORKDIR}/data/hooks/* ./data/hooks`
    end
 
    puts "Restoring mysql state..."
    puts `mysql #{db_name} < #{TMP_WORKDIR}/#{SQL_DUMP_FILE}`

    puts "Upgrading database structure..."
    Rake::Task["db:migrate"].invoke
    
    puts "Restoring repositories in #{repo_path}..."
    puts `mkdir -p #{repo_path}`
    puts `cp -rf #{TMP_WORKDIR}/repos/* #{repo_path}`
    puts `chown -R #{gitorious_user}:#{gitorious_user} #{repo_path}`
    
    puts "Rebuilding ~/.ssh/authorized_keys from user keys in database..."
    puts `su #{gitorious_user} -c "rm -f ~/.ssh/authorized_keys; bundle exec script/regenerate_ssh_keys ~/.ssh/authorized_keys"`

    puts "Recreating symlink to common hooks"
    puts `rm -f #{repo_path}/.hooks` 
    puts `ln -s #{File.expand_path('./data/hooks')} #{repo_path}/.hooks`
    
    puts "Cleaning up..."
    puts `rm -rf #{TMP_WORKDIR}`

    puts "Done restoring Gitorious from #{tarball_path}."
  end
end
