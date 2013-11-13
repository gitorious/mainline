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

class EventPresenter
  attr_reader :event, :view
  private :event, :view

  delegate :link_to, :h, :truncate, :dom_id, :pluralize, :ensplat_path,
    :repo_path, :repo_title, :sanitize, :content_tag, :to => :view

  def self.build(event, view)
    name  = "#{self.name}::#{event.action_name.split.join('_').classify}Event"
    klass = name.constantize
    klass.new(event, view)
  end

  def initialize(event, view)
    @event = event
    @view  = view
  end

  def actor
    user.fullname? ? user.fullname : user.login
  end

  def has_avatar?
    user && user.avatar
  end

  def body
    ''
  end

  private

  def action_for_event(key, options = {}, &block)
    parts = [I18n.t("application_helper.#{key}", options)]
    parts << block.call if block
    parts << view.time_ago(created_at)
    parts.join(' ')
  end

  def method_missing(name, *args, &block)
    if event.respond_to?(name)
      event.public_send(name, *args, &block)
    else
      super
    end
  end

end

Dir[Rails.root.join('app/presenters/event_presenter/*')].each do |file|
  require_dependency file
end
