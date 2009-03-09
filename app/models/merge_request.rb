#--
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
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
  has_many :messages, :as => :notifiable, :dependent => :destroy
  
  is_indexed :fields => ["proposal"], :include => [{
      :association_name => "user",
      :field => "login",
      :as => "proposed_by"
    }], :conditions => "status = 0"
  
  attr_protected :user_id, :status
    
  validates_presence_of :user, :source_repository, :target_repository, :ending_commit
  
  STATUS_PENDING_ACCEPTANCE_OF_TERMS = 0
  STATUS_OPEN = 1
  STATUS_MERGED = 2
  STATUS_REJECTED = 3
  
  named_scope :open, :conditions => { :status => STATUS_OPEN }
  named_scope :closed, :conditions => ["status in (?)", [STATUS_MERGED, STATUS_REJECTED]]
  
  def self.human_name
    I18n.t("activerecord.models.merge_request")
  end
  
  def self.statuses
    { "Open" => STATUS_OPEN, "Merged" => STATUS_MERGED, "Rejected" => STATUS_REJECTED, 'Pending' => STATUS_PENDING_ACCEPTANCE_OF_TERMS }
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
  
  def pending_acceptance_of_terms?
    status == STATUS_PENDING_ACCEPTANCE_OF_TERMS
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
    return [] if !target_repository
    @commits_for_selection ||= target_repository.git.commit_deltas_from(source_repository.git, target_branch, source_branch)
  end
  
  def applies_to_specific_commits?
    !!ending_commit
  end
  
  def commits_to_be_merged
    if applies_to_specific_commits?
      idx = commits_for_selection.index(commits_for_selection.find{|c| c.id == ending_commit})
      return idx ? commits_for_selection[0..idx] : []
    else
      return commits_for_selection
    end
  end
  
  def target_branches_for_selection
    return [] unless target_repository
    target_repository.git.branches || []
  end
  
  def breadcrumb_parent
    Breadcrumb::MergeRequests.new(target_repository)
  end
  
  def title
    source_repository.name
  end
  
  def acceptance_of_terms_required?
    target_repository.requires_signoff_on_merge_requests?
  end
  
  def confirmed_by_user
    self.status = STATUS_OPEN
    save
    message = messages.build(
      :sender => user, 
      :recipient => target_repository.user,
      :subject => I18n.t("mailer.request_notification", :login => source_repository.user.login, :title => target_repository.project.title),
      :body => proposal,
      :notifiable => self)    
    message.save
  end
  
  def terms_accepted(oauth_request_token, oauth_request_secret)
    validate_through_oauth(oauth_request_token, oauth_request_secret) do
      confirmed_by_user
    end
  end
  
  def validate_through_oauth(token, secret)
    yield if valid_oauth_credentials?(token, secret)
  end
  
  def valid_oauth_credentials?(token, secret)
    access_token = CONSUMER.build_access_token(token, secret)
    response = access_token.get("/agreements.xml")
    return Net::HTTPSuccess === response
  end
  
end
