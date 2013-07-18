# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class Admin::ProjectProposalsControllerTest < ActionController::TestCase
  context "Project approval workflow" do
    should "let users create project proposal & notify admins" do
      login_as_non_admin
      pre_count = ProjectProposal.all.count

      post :create, :project_proposal => new_proposal.attributes

      assert_equal pre_count+1, ProjectProposal.all.count
      assert_response :redirect
    end

    should "let admins approve project proposal" do
      proposal = new_proposal
      proposal.save
      pre_count = Project.all.count
      login_as_admin

      post :approve, :id => proposal.to_param

      assert_equal pre_count+1, Project.all.count
      assert !Project.all.last.private?
      assert_response :redirect
    end

    should "ensure that approved project is private if private by default is toggled" do
      Gitorious::Configuration.override({
        "enable_private_repositories" => true,
        "projects_default_private" => true
      }) do
        proposal = new_proposal
        proposal.save
        login_as_admin

        post :approve, :id => proposal.to_param

        assert Project.all.last.private?
      end
    end
  end

  def login_as_admin
    login_as :johan
  end

  def login_as_non_admin
    login_as :moe
  end

  def new_proposal
    p = ProjectProposal.new({ :title => "TopSecret#{rand(100000)}",
                              :description => "Lorem ipsum",
                              :creator => users(:moe) })
  end
end
