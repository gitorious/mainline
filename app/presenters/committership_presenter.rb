# encoding: utf-8
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

class CommittershipPresenter
  def self.collection(committerships, view_context)
    committerships.map { |c| new(c, view_context) }
  end

  attr_reader :committership, :view_context
  alias :v :view_context

  def initialize(committership, view_context)
    @committership = committership
    @view_context = view_context
  end

  def label
    label_type = " (#{committership.committer.class.human_name})"
    if super_group?
      v.link_to("Super Group*", "/about/faq")
    else
      v.link_to(committership.committer.title, committership.committer)
    end + label_type
  end

  def permissions
    committership.permission_list.join(', ')
  end

  def creator
    v.link_to(committership.creator.login, committership.creator) if committership.creator
  end

  def created_at
    I18n.l(committership.created_at, :format => :short)
  end

  def actions
    return delete_link if super_group?
    edit_link + delete_link
  end

  private

  def edit_link
    edit_url_params = [:edit, project, repository, committership]
    v.link_to(I18n.t("views.common.edit"), edit_url_params, :method => :get, :class => "btn")
  end

  def delete_link
    delete_url_params = [project, repository, committership]
    v.link_to(I18n.t("views.common.remove"), delete_url_params,
              :method => :delete, :class => "btn btn-danger",
              :confirm => confirmation_message)
  end

  def confirmation_message
    if last_admin?
      "You are about to remove the last committer with admin rights. Are you sure about this?"
    end
  end

  def last_admin?
    repository.committerships.last_admin?(committership)
  end

  def project
    repository.project
  end

  def repository
    committership.repository
  end

  def super_group?
    committership.id == SuperGroup.id
  end
end
