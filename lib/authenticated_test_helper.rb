module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    sign_in :user, user_instance(user)
  end

  def logout
    sign_out :user
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? "Basic #{Base64.encode64("#{users(user).email}:test")}" : nil
  end

  def authenticated?
    warden.authenticated?
  end

  # Sometimes user is a User
  def user_instance(sym_or_obj)
    sym_or_obj.is_a?(User) ? sym_or_obj : users(sym_or_obj)
  end

  def assert_redirected_to_login
    assert_redirected_to(new_user_session_path)
  end
end
