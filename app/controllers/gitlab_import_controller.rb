class GitlabImportController < ApplicationController
  before_filter :login_required

  def new
    redirect_to "#{params[:callback_url]}?repos=#{owned_repos_list}"
  end

  private

  def owned_repos_list
    current_user.exportable_repositories.map(&:url_path).sort.join(',')
  end

end
