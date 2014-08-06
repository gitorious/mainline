class GitHttpController < ApplicationController

  def authorize
    repository = get_repository
    user = get_user

    headers['Content-Type'] = 'text/plain'

    if RepositoryPolicy.allowed?(user, repository, command)
      repository.cloned_from(request.remote_ip, nil, nil, "http")
      headers['X-Accel-Redirect'] = x_accel_redirect_path(repository.real_gitdir)
      render nothing: true
    else
      if user
        render text: "Permission denied", status: 403
      else
        request_http_basic_authentication("Gitorious")

        if request.authorization.blank?
          self.response_body = "Anonymous access denied"
        else
          self.response_body = "Invalid username or password"
        end
      end
    end
  end

  private

  def get_repository
    path = "#{params[:project_slug]}/#{params[:repository_name]}"
    Repository.find_by_path(path) or raise ActiveRecord::RecordNotFound
  end

  def get_user
    authenticate_with_http_basic do |username, password|
      User.authenticate(username, password)
    end
  end

  def command
    regexp = /git[\s-](upload-pack|receive-pack)/
    params[:service].to_s[regexp, 1] || params[:slug].to_s[regexp, 1]
  end

  def x_accel_redirect_path(real_gitdir)
    if request.query_string.present?
      query_string = "?#{request.query_string}"
    end

    "/_internal/git/#{real_gitdir}#{params[:slug]}#{query_string}"
  end

end
