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

require "test_helper"

class CommentPresenterTest < ActiveSupport::TestCase
  context "#context" do
    should "render context" do
      comment = Comment.new(:context => "the foo")
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.context, "<code>the foo</code>"
    end

    should "not render context when blank" do
      comment = Comment.new
      presenter = CommentPresenter.new(comment, view_context)

      assert_blank presenter.context
    end
  end

  context "#state_changed" do
    should "render nothing when state_changed_to is nil" do
      comment = Comment.new
      presenter = CommentPresenter.new(comment, view_context)

      assert_blank presenter.state_changed
    end

    should "render only state changed to when state_changed_from is nil" do
      comment = Comment.new(:state_change => ['Open'])
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.state_changed, '<span class="label label-success">Open</span>'
    end

    should "render both state changed form and to" do
      comment = Comment.new(:state_change => ['Open', 'Closed'])
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.state_changed, '<span class="label label-success">Open</span>'
      assert_include presenter.state_changed, '<span class="label label-inverse">Closed</span>'
    end
  end

  context "#markdown" do
    should "render comment's markdown" do
      comment = Comment.new(:body => "*foo*")
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.markdown, '<em>foo</em>'
    end
  end

  context "#avatar" do
    should "render authors avatar" do
      author = users(:johan)
      author.avatar_file_name = "foo.png"

      comment = Comment.new(:user => author)
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.avatar, 'johan/thumb/foo.png'
    end

    should "render default avatar for removed author" do
      comment = Comment.new
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.avatar, Gitorious::View::AvatarHelper::DEFAULT_AVATAR_FILE
    end
  end

  context "#author_link" do
    should "render link to authors profile" do
      author = users(:johan)
      comment = Comment.new(:user => author)
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.author_link, 'johan'
      assert_include presenter.author_link, view_context.user_path(author)
    end

    should "render a placeholder when author was removed" do
      comment = Comment.new
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.author_link, 'Removed Author'
    end
  end

  context "#label" do
    should "render commit link if applies" do
      comment = comments(:first_merge_request_version_comment)
      comment.created_at = Time.parse("2013-10-17 10:12")
      presenter = CommentPresenter.new(comment, view_context)

      assert_include presenter.label, "#ffac0-a"
      assert_include presenter.label, "Oct 17 2013, 10:12."
    end

    should "render only date if not attached to any commit" do
      comment = Comment.new
      comment.created_at = Time.parse("2013-10-17 10:12")
      presenter = CommentPresenter.new(comment, view_context)

      assert_equal "Oct 17 2013, 10:12.", presenter.label.strip
    end
  end

  context "#edit_link" do
    def view_context_with_current_user(user)
      v = view_context
      v.stubs(:current_user => user)
      v
    end

    should "render edit link to the author" do
      comment = comments(:first_merge_request_version_comment)

      v = view_context_with_current_user(comment.user)
      v.stubs(:edit_comment_path).with(comment).returns("/path/to/comment")

      presenter = CommentPresenter.new(comment, v)

      assert_include presenter.edit_link, "Edit comment"
      assert_include presenter.edit_link, "/path/to/comment"
    end

    should "not render edit link for other users" do
      comment = comments(:first_merge_request_version_comment)
      v = view_context_with_current_user(users(:moe))
      presenter = CommentPresenter.new(comment, v)

      assert_blank presenter.edit_link
    end
  end
end
