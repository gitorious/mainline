# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

module Admin
  class ProjectProposalsController < AdminController
    before_filter :require_site_admin, :except => [:new, :create]

    def index
      render(:index, :locals => { :proposals => ProjectProposal.all })
    end

    def new
      render(:new, :locals => { :proposal => ProjectProposal.new })
    end

    def create
      proposal = ProjectProposal.new
      proposal.title = params[:project_proposal][:title]
      proposal.description = params[:project_proposal][:description]
      proposal.creator = current_user

      if proposal.name_clashes_with_existing_project?
        flash[:error] = "Project with that title already exists!"
        render(:new, :locals => { :proposal => proposal }) and return
      end

      if proposal.save
        notify_site_admins("A new project has been proposed",
          "Proposal for project #{proposal.title} submitted by #{proposal.creator.title}", proposal)
        flash[:notice] = "Project proposal created, admins have been notified and will review it."

        redirect_to current_user
      else
        render(:new, :locals => { :proposal => proposal })
      end
    end

    def approve
      proposal = ProjectProposal.find_by_id(params[:id])
      project = proposal.approve
      project.make_private if Gitorious.projects_default_private?
      notify_creator("Your '#{project.title}' project has been approved!", project.owner,
                     "Please update your project license, description etc.")
      flash[:notice] = "Project approved and created, user has been notified"
      redirect_to :action => :index
    end

    def reject
      proposal = ProjectProposal.find_by_id(params[:id])
      notify_creator("Your '#{proposal.title}' project was rejected", proposal.creator,
                     "Your project proposal was rejected. Please contact a site admin for clarification.")
      proposal.reject
      flash[:notice] = "Project rejected and removed, user has been notified"
      redirect_to :action => :index
    end

    protected
    def notify_site_admins(subject, body, proposal)
      User.admins.each do |admin|
        SendMessage.call(:sender => current_user,
                         :recipient => admin,
                         :subject => subject,
                         :notifiable => proposal,
                         :body => body)
      end
    end

    def notify_creator(subject, recipient, body)
      SendMessage.call(:sender => current_user,
                       :recipient => recipient,
                       :subject => subject,
                       :body => body)
    end
  end
end
