  require "openid"
  require "yadis"
# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  # render new.rhtml
  def new
  end

  def create
    if using_open_id?
      open_id_authentication(params[:openid_url])
    else
      password_authentication(params[:email], params[:password])
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  protected

  # if user doesn't exist, it gets created and activated,
  # else if the user already exists with same identity_url, it just logs in
  def open_id_authentication(openid_url)
    authenticate_with_open_id(openid_url, :required => [:nickname, :email], :optional => [:fullname]) do |result, identity_url, registration|
      if result.successful?
        @user = User.find_or_initialize_by_identity_url(identity_url)
        if @user.new_record?
          @user.login = registration['nickname']
          @user.fullname = registration['fullname']
          @user.email = registration['email']
          @user.save!
          @user.activate
        end
        self.current_user = @user
        successful_login
      else
        failed_login result.message, 'openid'
      end
    end
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = %Q{This login (<strong>#{@user.login}</strong>) already exists, 
      please <a href="#{@user.identity_url}"> choose a different persona/nickname 
      or modify the current one</a>}
    redirect_to login_path(:method => 'openid')
  end

  def password_authentication(email, password)
    ##self.current_user = User.authenticate(login, password)
    self.current_user = User.authenticate(email, password)
    if logged_in?
      successful_login
    else
      failed_login("Username/password didn't match, please try again.")
    end
  end

  def failed_login(message = "Authentication failed.",method="")
    if method==''
      flash.now[:error] = message
      render :action => 'new'
    else
      redirect_to login_path(:method=>method)
      flash[:error] = message
    end
  end

  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
    redirect_back_or_default('/')
    flash[:notice] = "Logged in successfully"
  end

end
