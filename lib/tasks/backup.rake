namespace :backup do

  # Full backup snapshot/restore for reasonably standard Gitorious
  # setups. Saves/restores current production db, local configuration
  # files and git repositories - in a single tarball.

  # ASSUMPTIONS:

  # 0. Both backup and restore tasks must be started from within
  # the root of your Gitorious installation.

  # 1 Should be run as root/superuser to preserve file/dir ownerships.

  # 2. Assumes that the gitorious installation is owned by the
  # "git" user.

  # 3. Leans on the 'mysql' util for the db backup, only
  # dumps/restores the gitorious_production db (not dev, test etc)

  # 4. Doesn't currently capture queue state, so you may want to shut
  # down the web frontend first and let the queues settle down before
  # using these snapshot/restore operations in production systems.

  # 5. Assumes that you have the time and disk-space to slurp down all
  # repos into a local tarball. Sites with huge amounts of repo data
  # may need custom backup schemes.

  # 6. Assumes that the location of the gitorious installation
  # remains the same between taking a snapshot and restoring it, since
  # repos symlink their hooks to the common hooks in the data/hooks dir.

  # 7. The restore step assumes minor to no changes in versions of
  # Gitorious between snapshot and subsequent restoration of a
  # backup. Major version jumps may necessitate a more manual restore
  # procedure due to changes in configurations, db schema, folder
  # structure etc.
  
  # EXAMPLES:
  
  # Simple dump of default tarball file in current directory:
  # sudo bundle exec rake backup:snapshot

  # Simple restore from default tarball in current directory:
  # sudo bundle exec rake backup:restore

  # More explicit: specify tarball path
  # sudo bundle exec env TARBALL_PATH="current_snapshot.sql" rake backup:snapshot
  # sudo bundle exec env TARBALL_PATH="current_snapshot.sql" rake backup:snapshot

  DEFAULT_TAR_PATH="snapshot.tar"
  SQL_DUMP_FILE="db_state.sql"
  TMP_WORKDIR="tmp-backup-workdir"

  def repo_path
    require 'yaml'
    conf = YAML::load(File.open('config/gitorious.yml'))
    conf['production']['repository_base_path']
  end
  
  desc "Simple state snapshot of the Gitorious instance to a single tarball."
  task :snapshot do
    tarball_path = ENV["TARBALL_PATH"] || DEFAULT_TAR_PATH

    puts "Initializing..."
    puts `rm -f #{tarball_path};rm -f #{SQL_DUMP_FILE}`
    puts `rm -rf #{TMP_WORKDIR}; mkdir #{TMP_WORKDIR}`
    puts `mkdir #{TMP_WORKDIR}/repos`
    puts `mkdir #{TMP_WORKDIR}/config`
    puts `mkdir -p #{TMP_WORKDIR}/data/hooks`
    
    puts "Backing up custom config files..."
    puts `cp ./config/gitorious.yml #{TMP_WORKDIR}/config`
    puts `cp ./config/authentication.yml #{TMP_WORKDIR}/config`
    puts `cp ./config/database.yml #{TMP_WORKDIR}/config`

    puts "Backing up custom hooks..."
    puts `cp ./data/hooks/custom-pre-receive #{TMP_WORKDIR}/data/hooks`
    puts `cp ./data/hooks/custom-post-receive #{TMP_WORKDIR}/data/hooks`
    puts `cp ./data/hooks/custom-update #{TMP_WORKDIR}/data/hooks`
    
    puts "Backing up mysql state..."
    puts `mysqldump gitorious_production > #{TMP_WORKDIR}/#{SQL_DUMP_FILE}`

    puts "Backing up repositories in #{repo_path}..."
    puts `cp -r #{repo_path}/* #{TMP_WORKDIR}/repos`
    
    puts "Archiving it all in #{tarball_path}..."
    puts `tar -czf #{tarball_path} #{TMP_WORKDIR}`
    
    puts "Cleaning up..."
    puts `rm -rf #{SQL_DUMP_FILE};rm -rf #{TMP_WORKDIR}`

    puts "Done! Backed up current Gitorious state to #{tarball_path}."
  end

  
  desc "Restores Gitorious instance to snapshot previously stored in tarball file."
  task :restore do
    tarball_path = ENV["TARBALL_PATH"] || DEFAULT_TAR_PATH

    puts "Preparing..."
    puts `rm -rf #{TMP_WORKDIR};tar -xf #{tarball_path}`

    puts "Restoring custom config files..."
    puts `cp #{TMP_WORKDIR}/config/* ./config`

    puts "Restoring custom hooks..."
    puts `cp #{TMP_WORKDIR}/data/hooks/* ./data/hooks`

    puts "Restoring mysql state..."
    puts `mysql gitorious_production < #{TMP_WORKDIR}/#{SQL_DUMP_FILE}`
   
    puts "Restoring repositories in #{repo_path}..."
    puts `mkdir -p #{repo_path}`
    puts `cp -r #{TMP_WORKDIR}/repos/* #{repo_path}`

    puts "Rebuilding ~/.ssh/authorized_keys from user keys in database..."
    puts `sudo su git -c "rm ~/.ssh/authorized_keys; bundle exec script/regenerate_ssh_keys ~/.ssh/authorized_keys"`
    
    puts "Cleaning up..."
    puts `rm -rf #{TMP_WORKDIR}`

    puts "Done restoring Gitorious from #{tarball_path}."
  end
end
