# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

module GroupBehavior
  NAME_FORMAT = /[a-z0-9\-]+/.freeze

  def self.extended(klass)
    klass.belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
    klass.has_many(:repositories, :as => :owner, :conditions => ["kind NOT IN (?)",
                                                                 Repository::KINDS_INTERNAL_REPO],
      :dependent => :destroy)
    klass.has_many(:cloneable_repositories, :as => :owner, :class_name => "Repository",
      :conditions => ["kind != ?", Repository::KIND_TRACKING_REPO])
    klass.has_many(:projects, :as => :owner)
    klass.validates_presence_of(:name)
    klass.validates_uniqueness_of(:name)
    klass.validates_format_of(:name, :with => /^#{NAME_FORMAT}$/,
      :message => "Must be alphanumeric, and optional dash")

    klass.before_validation :downcase_name
    klass.has_many :_committerships, :as => :committer, :dependent => :destroy
    klass.has_many :content_memberships, :as => :member, :dependent => :destroy

    def klass.find_fuzzy(query)
      where("LOWER(name) LIKE ?", "%" + query.downcase + "%").limit(10)
    end
  end

  def human_name
    I18n.t("activerecord.models.group")
  end

  module InstanceMethods
    def committerships
      GroupCommitterships.new(self)
    end

    def to_param_with_prefix
      "+#{to_param}"
    end

    def downcase_name
      name.downcase! if name
    end

    def memberships_modifiable_by?(user)
      user_role(user) == Role.admin
    end
  end
end
