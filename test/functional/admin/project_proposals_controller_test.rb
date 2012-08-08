# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require File.dirname(__FILE__) + "/../../test_helper"

class Admin::ProjectProposalsControllerTest < ActionController::TestCase

  def setup
    setup_ssl_from_config
  end
  
  context "Routing" do
    should "recognize project proposal actions" do
      assert_recognizes({:controller => "admin/project_proposals",
                          :action => "index"},
                        {:path => "/admin/project_proposals", :method => :get})

      assert_recognizes({:controller => "admin/project_proposals",
                          :action => "new"},
                        {:path => "/admin/project_proposals/new", :method => :get})

      assert_recognizes({:controller => "admin/project_proposals",
                          :action => "create"},
                        {:path => "/admin/project_proposals/create", :method => :post})

      assert_recognizes({:controller => "admin/project_proposals",
                          :action => "approve",
                          :id => "1"},
                        {:path => "/admin/project_proposals/approve/1", :method => :post})

      assert_recognizes({:controller => "admin/project_proposals",
                          :action => "reject",
                          :id => "1"},
                        {:path => "/admin/project_proposals/reject/1", :method => :post})
    end
  end

  context "Project approval workflow" do
    
    should "let users create project proposal & notify admins" do
      login_as_non_admin
      pre_count = ProjectProposal.all.count
      post :create, :project_proposal => new_proposal
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
      GitoriousConfig["enable_private_repositories"] = true
      GitoriousConfig["repos_and_projects_private_by_default"] = true
      proposal = new_proposal
      proposal.save
      login_as_admin
      post :approve, :id => proposal.to_param
      assert Project.all.last.private?
      GitoriousConfig["enable_private_repositories"] = false
      GitoriousConfig["repos_and_projects_private_by_default"] = false
    end
    
  end   
  
  def login_as_admin
    login_as :johan
  end

  def login_as_non_admin
    login_as :moe
  end

  def new_proposal
    p = ProjectProposal.new({:title => "TopSecret#{rand(100000)}",
                              :description => "Lorem ipsum",
                              :creator => users(:moe)})
  end
end
