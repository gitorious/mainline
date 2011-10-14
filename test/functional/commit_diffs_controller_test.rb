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

class CommitDiffsControllerTest < ActionController::TestCase
  def setup
    @project = projects(:johans)
    @repository = @project.repositories.mainlines.first
    @repository.update_attribute(:ready, true)
    @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
    Repository.any_instance.stubs(:full_repository_path).returns(grit_test_repo("dot_git"))
    @grit = Grit::Repo.new(grit_test_repo("dot_git"), :is_bare => true)
    Repository.any_instance.stubs(:git).returns(@grit)
  end

  context "index" do
    should "not show diffs for the initial commit" do
      commit = @grit.commit(@sha)
      commit.stubs(:parents).returns([])
      @grit.expects(:commit).returns(commit)

      get(:index, {
            :project_id => @project.to_param, 
            :repository_id => @repository.to_param,
            :id => @sha
          })

      assert_equal [], assigns(:diffs)
      assert_select "#content p", /This is the initial commit in this repository/
    end

    should "show diffs for successive commits" do
      get(:index, {
            :project_id => @project.to_param, 
            :repository_id => @repository.to_param,
            :id => "5a0943123f6872e75a9b1dd0b6519dd42a186fda"
          })

      assert_response :success
    end

    should "yield 404 if commit does not exist" do
      get(:index,
          :project_id => @project.slug,
          :repository_id => @repository.name,
          :id => "0000000")

      assert_response 404
    end
  end

  context "Comparing arbitrary commits" do
    should "pick the correct commits" do
      Grit::Commit.expects(:diff).with(@repository.git, OTHER_SHA, @sha).returns([])
      get(:compare,
        :project_id => @project.slug,
        :repository_id => @repository.name,
        :from_id => OTHER_SHA,
        :id => @sha,
        :fragment => "true")
      assert_response :success
    end
  end

  context "Routing" do
    should "route commit diffs index" do
      assert_recognizes({
        :controller => "commit_diffs", 
        :action => "index", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      }, { :path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}/diffs", :method => :get })

      assert_generates("/#{@project.to_param}/#{@repository.to_param}/commit/#{@sha}/diffs", {
        :controller => "commit_diffs", 
        :action => "index", 
        :project_id => @project.to_param,
        :repository_id => @repository.to_param,
        :id => @sha,
      })
    end

    should "route comparison between two commits" do
      assert_recognizes({:controller => "commit_diffs",
          :action => "compare",
          :project_id => @project.to_param,
          :repository_id => @repository.to_param,
          :from_id => SHA,
          :id => OTHER_SHA},
        {:path => "/#{@project.to_param}/#{@repository.to_param}/commit/#{SHA}/diffs/#{OTHER_SHA}"})
    end
  end
end
