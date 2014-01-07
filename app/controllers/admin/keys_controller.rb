# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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
  class KeysController < AdminController
    include Gitorious::Messaging::Publisher

    before_filter :find_user

    attr_reader :user

    def index
      render :index, locals: { user: user }
    end

    def new
      render :new, locals: { user: user, ssh_key: user.ssh_keys.build }
    end

    def create
      outcome = CreateSshKey.new(self, user).execute(params[:ssh_key])

      outcome.success do |result|
        flash[:notice] = I18n.t("keys_controller.create_notice")
        redirect_to admin_user_keys_path(user)
      end

      outcome.failure do |ssh_key|
        render :new, locals: { user: user, ssh_key: ssh_key }
      end
    end

    def destroy
      outcome = DestroySshKey.new(self, user).execute(params)

      outcome.success do
        flash[:notice] = I18n.t("keys_controller.destroy_notice")
        redirect_to admin_user_keys_path(user)
      end
    end

    private

    # def paginated_repositories
    #   scope = Repository.where("ready = false AND kind != #{Repository::KIND_TRACKING_REPO}")
    #   page = (params[:page] || 1).to_i
    #   repositories, pages = JustPaginate.paginate(page, Repository.per_page, scope.count) do |range|
    #     scope.offset(range.first).limit(range.count).includes(:project)
    #   end
    #   [repositories, pages, page]
    # end

    def find_user
      @user = User.find_by_login!(params[:user_id])
    end

  end
end
