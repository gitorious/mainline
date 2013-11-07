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

class CommentPresenter
  attr_reader :comment, :view_context
  alias :v :view_context

  def initialize(comment, view_context)
    @comment = comment
    @view_context = view_context
  end

  def id
    comment.id
  end

  def body?
    comment.body?
  end

  def context
    return if comment.context.blank?
    v.content_tag :blockquote do
      v.content_tag :pre, :class => "diff-comment-context" do
        v.content_tag(:code, comment.context)
      end
    end
  end

  def state_changed
    return unless comment.state_changed_to

    v.content_tag(:span) {
      "→ State changed #{state_changed_from} #{state_changed_to}".html_safe
    }
  end

  def markdown
    v.render_markdown(comment.body, :auto_link).html_safe
  end

  def avatar
    default_url = Gitorious::View::AvatarHelper::DEFAULT_USER_AVATAR_FILE
    url = comment.user ? v.avatar_url(comment.user, :size => 24) : default_url
    v.image_tag url, :size => '24x24', :alt => "avatar", :class => "gts-avatar"
  end

  def author_link
    return v.content_tag :span, "Removed Author" unless comment.user
    v.link_to(comment.user.login, v.user_path(comment.user))
  end

  def edit_link
    return unless v.can_edit?(v.current_user, comment)
    v.link_to(
      '<i class="icon icon-edit"></i> Edit'.html_safe,
      v.edit_comment_path(comment),
      :class => 'btn btn-small'
    )
  end

  def timestamp
    v.content_tag(:span, :class => 'gts-timestamp', :title => comment.created_at.utc) {
      v.time_ago_in_words(comment.created_at)+' ago'
    }
  end

  def line_number
    return unless comment.applies_to_line_numbers?
    link = v.link_to("##{comment.sha1[0...7]}", v.project_repository_commit_path(comment.project, comment.repository, comment.sha1))
    " commented on #{link}".html_safe
  end

  private

  def time
    comment.created_at.strftime("%b %-d %Y, %H:%M.")
  end

  def state_changed_from
    return "" unless comment.state_changed_from
    state_changed_span("from", comment.state_changed_from)
  end

  def state_changed_to
    state_changed_span("to", comment.state_changed_to)
  end

  def state_changed_span(label, state)
    label_class = v.status_open?(state) ? 'label-success' : 'label-inverse'
    span = v.content_tag(:span, state, :class => "label #{label_class}")
    "#{label} #{span}"
  end
end

