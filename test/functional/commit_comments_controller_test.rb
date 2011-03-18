# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
require File.dirname(__FILE__) + '/../test_helper'

class CommitCommentsControllerTest < ActionController::TestCase
  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)
    @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
  end

  context "index" do
    should "display comments" do
      comment = Comment.create!({
                        :user => users(:johan),
                        :body => "foo",
                        :sha1 => @sha,
                        :target => @repository,
                        :project => @repository.project,
                      })

      get(:index, {
            :project_id => @project.slug, 
            :repository_id => @repository.name,
            :id => @sha
          })

      assert_equal [comment], assigns(:comments)
      assert_equal 1, assigns(:comment_count)
    end

    should "have a different last-modified if there is a comment" do
      Comment.create!({
          :user => users(:johan),
          :body => "foo",
          :sha1 => @sha,
          :target => @repository,
          :project => @repository.project,
      })

      get(:index,
          :project_id => @project.slug,
          :repository_id => @repository.name,
          :id => @sha)

      assert_response :success
      assert_not_equal "Fri, 18 Apr 2008 23:26:07 GMT", @response.headers["Last-Modified"]
    end
  end

  context "Routing" do
    should "route commits index" do
      assert_recognizes({
        :controller => "commit_comments", 
        :action => "index", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      }, { :path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}/comments", :method => :get })

      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}/comments", {
        :controller => "commit_comments", 
        :action => "index", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      })
    end
  end
end
