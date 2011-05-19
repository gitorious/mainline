module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    if user
      sign_in :user, user_instance(user)
    else
      sign_out :user
    end
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? "Basic #{Base64.encode64("#{users(user).email}:test")}" : nil
  end

  # Sometimes user is a User
  def user_instance(sym_or_obj)
    sym_or_obj.is_a?(User) ? sym_or_obj : users(sym_or_obj)
  end
end
