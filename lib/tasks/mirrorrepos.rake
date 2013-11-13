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

require File.join(File.dirname(__FILE__), "../gitorious")

namespace :mirror do

  # Creating/synching symlinks to all repos in a separate folder

  # Designate a folder where symlinks to all current repository directories
  # are created. Handy for hosting Gitweb, cgit etc from a separate folder - especially
  # when sharding/hashing the actual repository directories in Gitorious, in which case
  # the folder structure becomes less than human readable when browsing from Gitweb.
  #
  # To keep this updated, schedule regular/frequent runs of this rake task (e.g. cron)

  # EXAMPLE:
  #
  # Run this from the root of your gitorious installation (where you normally run rake tasks)
  # sudo bundle exec rake mirror:symlinkedrepos RAILS_ENV=production
  #

  desc "Create mirror directory with symlinks to all current regular repository paths"
  task :symlinkedrepos => :environment do
    base = Gitorious::Configuration.get("repository_base_path")
    default_mirror_base_path = "#{base}/../mirrored-public-repos"
    mirror_base = ENV["MIRROR_BASEDIR"]
    mirror_base = default_mirror_base_path if mirror_base.nil? || mirror_base.strip == ""
    owner = Gitorious.user

    # create symlink dir if not there already
    puts `mkdir -p #{mirror_base}`

    # remove any current symlinks
    puts `rm -rf #{mirror_base}/*`

    # rebuild symlinks for all standard repos (omit private repos, wiki repos etc)
    repo_data = Repository.regular.each do |r|
      if !r.private?
        base = Gitorious::Configuration.get("repository_base_path")
        actual_path = "#{base}/#{r.real_gitdir}"
        repo_parent_dir = Pathname.new(r.url_path).dirname
        project_dir = "#{mirror_base}/#{repo_parent_dir}"
        puts `mkdir -p #{project_dir}`
        symlink_path = "#{project_dir}/#{r.name}"
        puts `ln -fs #{actual_path} #{symlink_path}`
      end
    end

    # make sure gitorious user owns all repo symlinks
    puts `chown -R #{owner}:#{owner} #{mirror_base}`
  end
end
