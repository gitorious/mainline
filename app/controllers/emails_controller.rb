class EmailsController < ApplicationController
  before_filter :login_required
  before_filter :find_user
  before_filter :require_current_user
  
  def index
    @emails = @user.email_aliases
  end
  
  def new
    @email = @user.email_aliases.new
  end
  
  def create
    @email = @user.email_aliases.new(params[:email])
    
    if @email.save
      flash[:success] = "You will receive an email asking you to confirm ownership of #{@email.address}"
      redirect_to user_emails_path(@user)
    else
      render "new"
    end
  end
  
  def confirm
    email = current_user.email_aliases.find_in_state(:first, :pending, 
              :conditions => {:confirmation_code => params[:id]})
    if email
      email.confirm!
      flash[:success] = "#{email.address} is now confirmed as belonging to you"
      redirect_to user_emails_path(@user) and return
    else
      flash[:error] = "The confirmation is incorrect"
      redirect_to user_path(@user)
    end
  end
  
  def destroy
    @email = @user.email_aliases.find_by_id(params[:id])
    if @email.destroy
      flash[:success] = "Email alias deleted"
    end
    redirect_to user_emails_path(@user)
  end
  
  protected
    def find_user
      @user = User.find_by_login!(params[:user_id])
    end
end
