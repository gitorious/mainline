class UsersController < ApplicationController
  # render new.rhtml
  def new
  end

  def create
    @user = User.new(params[:user])
    @user.save!
    self.current_user = @user
    redirect_back_or_default('/')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def activate
    if user = User.find_by_activation_code(params[:activation_code])
      self.current_user = user
      if logged_in? && !current_user.activated?
        current_user.activate
        flash[:notice] = "Signup complete!"
      end
    end
    redirect_back_or_default('/')
  end

end
