class GitlabImportController < ApplicationController
  before_filter :login_required

  def new
    redirect_to "#{params[:callback_url]}?repos=#{owned_repos_list}"
  end

  private

  def owned_repos_list
    current_user.owned_repositories.map(&:url_path).join(',')
  end

end
