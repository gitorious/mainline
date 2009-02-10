#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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

class MergeRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :source_repository, :class_name => 'Repository'
  belongs_to :target_repository, :class_name => 'Repository'
  has_many   :events, :as => :target, :dependent => :destroy
  
  is_indexed :fields => ["proposal"], :include => [{
      :association_name => "user",
      :field => "login",
      :as => "proposed_by"
    }], :conditions => "status = 0"
  
  attr_protected :user_id, :status
    
  validates_presence_of :user, :source_repository, :target_repository, :ending_commit
  
  STATUS_OPEN = 0
  STATUS_MERGED = 1
  STATUS_REJECTED = 2
  
  def self.human_name
    I18n.t("activerecord.models.merge_request")
  end
  
  def self.statuses
    { "Open" => STATUS_OPEN, "Merged" => STATUS_MERGED, "Rejected" => STATUS_REJECTED }
  end
  
  def self.count_open
    count(:all, :conditions => {:status => STATUS_OPEN})
  end
  
  def status_string
    self.class.statuses.invert[status].downcase
  end
  
  def open?
    status == STATUS_OPEN
  end
  
  def merged?
    status == STATUS_MERGED
  end
  
  def rejected?
    status == STATUS_REJECTED
  end
  
  def source_branch
    super || "master"
  end
  
  def target_branch
    super || "master"
  end
  
  def source_name
    if source_repository
      "#{source_repository.name}:#{source_branch}"
    end
  end
  
  def target_name
    if target_repository
      "#{target_repository.name}:#{target_branch}"
    end
  end
  
  def resolvable_by?(candidate)
    candidate.can_write_to?(target_repository)
  end
  
  def commits_for_selection
    @commits_for_selection ||= target_repository.git.commit_deltas_from(source_repository.git, target_branch, source_branch)
  end
  
  def applies_to_specific_commits?
    !!ending_commit
  end
  
  def commits_to_be_merged
    if applies_to_specific_commits?
      l = commits_for_selection.index(commits_for_selection.find{|c|c.id == ending_commit})
      return l ? commits_for_selection[0..l] : commits_for_selection
    else
      return commits_for_selection
    end
  end
  
  def breadcrumb_parent
    Breadcrumb::MergeRequests.new(target_repository)
  end
  
  def title
    "#{source_repository.name}"
  end
  
end
