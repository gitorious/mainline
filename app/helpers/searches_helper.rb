# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

module SearchesHelper
  def presenter(result)
    case result
    when Project
      ProjectPresenter.new(result)
    when Repository
      RepositoryPresenter.new(result)
    when MergeRequest
      MergeRequestPresenter.new(result)
    end
  end

  class Presenter
    include ERB::Util
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper
  end

  class ProjectPresenter < Presenter

    def initialize(obj)
      @project = obj
    end

    def title
      h(@project.title)
    end

    def url
      @project
    end

    def body
      @project.description
    end

    def tag_list
      @project.tag_list.map do |tag|
        link_to(h(tag), "/search?q=%40category+#{h(tag)}")
      end.to_sentence
    end

    def summary
      "The #{h(title)} project is labeled with #{tag_list}".html_safe
    end
  end

  class RepositoryPresenter < Presenter
    def initialize(obj)
      @repository = obj
    end

    def title
      [h(@repository.project.slug), h(@repository.name)].join("/")
    end

    def url
      [@repository.project, @repository]
    end

    def body
      @repository.description
    end

    def summary
      "The #{title} repository in #{h(@repository.project.slug)}"
    end
  end

  class MergeRequestPresenter < Presenter
    def initialize(obj)
      @merge_request = obj
    end

    def title
      h(@merge_request.summary) || "merge request ##{@merge_request.sequence_number}"
    end

    def url
      [@merge_request.target_repository.project, @merge_request.target_repository, @merge_request]
    end

    def body
      @merge_request.proposal
    end

    def summary
      "An #{@merge_request.status_tag} merge request to #{@merge_request.target_repository.project.slug}/#{@merge_request.target_repository.name}"
    end
  end
end
