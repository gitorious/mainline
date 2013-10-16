# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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
  class RepositoriesController < AdminController
    def index
      begin
        repositories, total_pages, page = paginated_repositories
      rescue RangeError => err
        flash[:error] = "Page #{page} does not exist"
        redirect_to(admin_repositories_path, :status => 307) and return
      end

      render("index", :locals => {
          :repositories => repositories,
          :total_pages => total_pages,
          :page => page
        })
    end

    def recreate
      repository = Repository.find(params[:id])
      CreateProjectRepositoryCommand.new(Gitorious::App).schedule_creation(repository)
      flash[:notice] = "Recreation message posted"
      redirect_to(:action => :index)
    end

    private
    def paginated_repositories
      scope = Repository.where("ready = false AND kind != #{Repository::KIND_TRACKING_REPO}")
      page = (params[:page] || 1).to_i
      repositories, pages = JustPaginate.paginate(page, Repository.per_page, scope.count) do |range|
        scope.offset(range.first).limit(range.count).includes(:project)
      end
      [repositories, pages, page]
    end
  end
end
