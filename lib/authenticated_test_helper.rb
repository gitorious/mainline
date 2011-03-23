module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    @request.session[:user_id] = user ? user_instance(user).id : nil
    @request.session_options[:expire_after] = 1.hour
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? "Basic #{Base64.encode64("#{users(user).email}:test")}" : nil
  end

  # Sometimes user is a User
  def user_instance(sym_or_obj)
    sym_or_obj.is_a?(User) ? sym_or_obj : users(sym_or_obj)
  end
end
