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
end
