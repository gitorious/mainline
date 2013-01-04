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

class ProjectProposalTest < ActiveSupport::TestCase

  context "Project name clash detection" do
    should "return true if project with same name exists" do
      proposal = ProjectProposal.new
      existing_title =  projects(:johans).title
      proposal.title = existing_title
      assert proposal.name_clashes_with_existing_project?
    end

    should "return false if no current project shared name with proposed project" do
      proposal = ProjectProposal.new
      proposal.title = "This project title not in fixtures"
      assert !proposal.name_clashes_with_existing_project?
    end
  end

  context "Approval" do
    should "destroy the proposal" do
      p = ProjectProposal.create({:title => "Skunkworks",
                                   :description => "Lorem ipsum",
                                   :creator => users(:moe)})
      p.save
      p.approve
      assert p.destroyed?
    end

    should "create and return project with same metadata as proposal" do
      proposal = ProjectProposal.create({:title => "Skunkworks",
                                   :description => "Lorem ipsum",
                                   :creator => users(:moe)})
      proposal.save
      inital_project_count = Project.all.count
      project = proposal.approve
      assert_equal inital_project_count+1, Project.all.count
      assert_equal project.title, proposal.title
      assert_equal project.slug, proposal.title.gsub(" ", "-").downcase
      assert_equal project.description, proposal.description
      assert_equal project.user, proposal.creator
      assert_equal project.owner, proposal.creator
    end
  end

  context "Rejection" do
    should "just destroy the proposal" do
      proposal = ProjectProposal.new
      proposal.save
      proposal.reject
      assert proposal.destroyed?
    end
  end

end
