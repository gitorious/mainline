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
require "commit_comments_json_presenter"

class App
  def user_path(user); "/~#{user.login}"; end
  def avatar_url(user); "http://www.gravatar.com/avatar/a59f9d19e6a527f11b016650dde6f4c9&amp;default=http://gitorious.test/images/default_face.gif"; end
end

class CommitCommentsJSONPresenterTest < MiniTest::Spec
  describe "#hash_for" do
    before do
      @user = User.new(:login => "cjohansen", :fullname => "Christian Johansen")
    end

    it "returns empty structure for no comments" do
      presenter = CommitCommentsJSONPresenter.new(App.new, [])

      assert_equal({ "commit" => [], "diffs" => {} }, presenter.hash_for(nil))
    end

    it "returns array of commit comments" do
      presenter = CommitCommentsJSONPresenter.new(App.new, [Comment.new({
              :user => @user,
              :body => "Yup",
              :created_at => DateTime.new(2013, 1, 1)
            })])

      assert_equal({
          "commit"=> [{
              "author" => {
                "profilePath" => "/~cjohansen",
                "avatarPath" => "http://www.gravatar.com/avatar/a59f9d19e6a527f11b016650dde6f4c9&amp;default=http://gitorious.test/images/default_face.gif",
                "login" => "cjohansen",
                "name" => "Christian Johansen"
              },
              "body" => "Yup",
              "createdAt" => "2013-01-01T00:00:00+00:00",
              "firstLine" => nil,
              "lastLine" => nil,
              "context" => nil,
              "path" => nil
            }],
          "diffs"=>{}
        }, presenter.hash_for(nil))
    end

    it "groups diff comments" do
      presenter = CommitCommentsJSONPresenter.new(App.new, [Comment.new({
              :user => @user,
              :body => "Yup",
              :created_at => DateTime.new(2013, 1, 1)
            }), Comment.new({
              :user => @user,
              :body => "Yup",
              :created_at => DateTime.new(2013, 1, 1),
              :path => "some/path.rb",
              :first_line_number => "0-1",
              :last_line_number => "0-1"
            }), Comment.new({
              :user => @user,
              :body => "Yup",
              :created_at => DateTime.new(2013, 1, 1),
              :path => "some/other/path.rb",
              :first_line_number => "0-1",
              :last_line_number => "0-1"
            }), Comment.new({
              :user => @user,
              :body => "Yup",
              :created_at => DateTime.new(2013, 1, 1),
              :path => "some/path.rb",
              :first_line_number => "0-1",
              :last_line_number => "0-1"
            })])

      comments = presenter.hash_for(nil)
      assert_equal 1, comments["commit"].length
      assert_equal 1, comments["diffs"]["some/other/path.rb"].length
      assert_equal 2, comments["diffs"]["some/path.rb"].length
    end
  end
end
