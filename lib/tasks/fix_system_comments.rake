# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

desc "Disables edition of system comments in merge requests"
task :fix_system_comments => :environment do
  comments = Comment.where(:target_type => MergeRequestVersion.name)
  new_versions = comments.where('body like "Pushed new version %"')
  puts "Disabling edition of #{new_versions.count}/#{comments.count} merge request version comments"
  new_versions.update_all(:editable => false)
end
