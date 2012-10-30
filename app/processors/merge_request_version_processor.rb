# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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

class MergeRequestVersionProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousMergeRequestVersionDeletion"

  def on_message(message)
    @message = message
    delete_branch
  end

  def delete_branch
    begin
      source_repository.git.git.push({:timeout => false},
        tracking_repository_path, ":#{target_branch_name}")
    rescue
      logger.error("Unable to remove branch #{target_branch_name} in #{tracking_repository_path}")
    end
  end

  def tracking_repository_path
    @message["tracking_repository_path"]
  end

  def source_repository_path
    @message["source_repository_path"]
  end

  def target_branch_name
    @message["target_branch_name"]
  end

  def source_repository
    Repository.find(@message["source_repository_id"])
  end
end
