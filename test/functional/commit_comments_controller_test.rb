# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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
require "create_commit_comment"

class CommitCommentsControllerTest < ActionController::TestCase
  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)
    @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
    @user = users(:zmalltalker)
    Repository.any_instance.stubs(:has_commits?).returns(true)
    Repository.any_instance.stubs(:head_candidate_name).returns("master")
  end

  context "index" do
    should "list comments" do
      create_comment

      get(:index, params(:format => "json"))

      comments = JSON.parse(response.body)
      assert_match "Hey man!", comments["commit"][0]["body"]
    end
  end

  context "creating commit comments" do
    should "add comment to commit" do
      login_as(@user)
      post(:create, params(comment: { :body => "Look at me!" }, format: 'json'))

      assert_response :ok
      assert_equal "Look at me!", Comment.last.body
      assert_equal @user, Comment.last.user
    end

    should "add inline comment to commit" do
      login_as(@user)
      post(:create, params(:comment => {
            :body => "Look at me!",
            :path => "some/path.rb",
            :lines => "0-10:0-10+0"
          }))

      assert_equal "some/path.rb", Comment.last.path
      assert_equal "0-10", Comment.last.first_line_number
    end
  end

  context "update" do
    setup do
      @comment = CreateCommitComment.new(@user, @repository, @sha).execute({
          :body => "tis my comment'"
        }).result
    end

    should "update comment" do
      login_as(@user)

      put(:update, params(id: @comment.id, comment: { body: 'foobar' }, format: 'json'))

      assert_response :ok
    end
  end

  context "With private projects" do
    setup do
      enable_private_repositories
    end

    should "disallow unauthorized user from listing comments" do
      comment = create_comment(users(:johan))
      get(:index, params(:format => "json"))
      assert_response 403
    end

    should "allow authorized user to list comments" do
      login_as :johan
      comment = create_comment(users(:johan))
      get(:index, params(:format => "json"))
      assert_response 200
    end

    should "allow authorized user to update comments" do
      login_as :johan
      comment = create_comment(users(:johan))
      put(:update, params(id: comment.id, comment: { body: 'foobar' }, format: 'json'))
      assert_response 200
    end
  end

  context "With private repositories" do
    setup do
      enable_private_repositories(@repository)
    end

    should "disallow unauthorized user from listing comments" do
      comment = create_comment(users(:johan))
      get(:index, params(:format => "json"))
      assert_response 403
    end

    should "allow authorized user to list comments" do
      login_as :johan
      comment = create_comment(users(:johan))
      get(:index, params(:format => "json"))
      assert_response 200
    end

    should "disallow unauthorized user from updating comment" do
      login_as(:moe)
      comment = create_comment(users(:johan))
      put(:update, params(id: comment.id, comment: { body: 'foobar' }, format: 'json'))
      assert_response 403
    end

    should "allow authorized user to update comments" do
      login_as :johan
      comment = create_comment(users(:johan))
      put(:update, params(id: comment.id, comment: { body: 'foobar' }, format: 'json'))
      assert_response 200
    end
  end

  private
  def create_comment(owner = @user)
    CreateCommitComment.new(owner, @repository, @sha).execute(:body => "Hey man!").result
  end

  def params(param = {})
    param.merge({
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :ref => @sha
      })
  end
end
