class AccountsController < ApplicationController
  before_filter :login_required
  
  def show
  end
  
  def edit  
    @user = current_user  
  end
  
  def update
    @user = current_user
    current_user.email = params[:user][:email] if params[:user][:email]
    current_user.password = params[:user][:password] if params[:user][:password]
    if params[:user][:password_confirmation]
      current_user.password_confirmation = params[:user][:password_confirmation]
    end
    if current_user.save
      flash[:notice] = "Your account details was updated"
      redirect_to account_path
    else
      render :action => "edit"
    end
  end
end
