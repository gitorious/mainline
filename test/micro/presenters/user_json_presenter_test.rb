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
require "fast_test_helper"
require "user_json_presenter"

class App
  def root_path; "/"; end
  def user_path(user); "/~#{user.login}"; end
  def edit_user_path(user); "/~#{user.login}/edit"; end
  def messages_path; "/messages"; end
  def logout_path; "/logout"; end
  def avatar_url(user); "http://www.gravatar.com/avatar/a59f9d19e6a527f11b016650dde6f4c9&amp;default=http://gitorious.test/images/default_face.gif"; end
end

class UnreadMessages
  def self.unread_count
    1
  end
end

class UserMessages
  def self.for(user)
    UnreadMessages
  end
end

class UserJSONPresenterTest < MiniTest::Spec
  describe "#to_hash" do
    it "returns empty hash if no user" do
      presenter = UserJSONPresenter.new(App.new, nil)

      assert_equal({}, presenter.to_hash)
    end

    it "returns hash with user data" do
      user = User.new(:login => "cjohansen")
      presenter = UserJSONPresenter.new(App.new, user)

      assert_equal "cjohansen", presenter.to_hash["user"]["login"]
    end

    it "incudes unread message count" do
      user = User.new(:login => "cjohansen")
      presenter = UserJSONPresenter.new(App.new, user)

      assert_equal 1, presenter.to_hash["user"]["unreadMessageCount"]
    end

    it "incudes user paths" do
      user = User.new(:login => "cjohansen")
      presenter = UserJSONPresenter.new(App.new, user)

      hash = presenter.to_hash["user"]
      assert_equal "/", hash["dashboardPath"]
      assert_equal "/~cjohansen/edit", hash["editPath"]
      assert_equal "/~cjohansen", hash["profilePath"]
      assert_equal "/messages", hash["messagesPath"]
      assert_equal "/logout", hash["logoutPath"]
      assert_equal "http://www.gravatar.com/avatar/a59f9d19e6a527f11b016650dde6f4c9&amp;default=http://gitorious.test/images/default_face.gif", hash["avatarUrl"]
    end
  end
end
