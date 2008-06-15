class AccountsController < ApplicationController
  before_filter :login_required
  
  def show
  end
  
  def edit  
    @user = current_user  
  end
  
  def update
    @user = current_user
    @user.attributes = params[:user]
    if current_user.save
      flash[:notice] = "Your account details was updated"
      redirect_to account_path
    else
      render :action => "edit"
    end
  end
  
  def password
    @user = current_user
  end
  
  def update_password
    @user = current_user
    if User.authenticate(current_user.email, params[:user][:current_password]) || @user.is_openid_only?
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      if @user.save
        flash[:notice] = "Your password has been changed"
        redirect_to account_path
      else
        render :action => "password"
      end
    else
      flash[:error] = "Your current password doesn't seem to match the one your supplied"
      render :action => "password"
    end
  end
end
