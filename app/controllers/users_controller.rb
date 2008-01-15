class UsersController < ApplicationController
  # render new.rhtml
  def new
  end
  
  def show
    @user = User.find_by_login!(params[:id])
    @repositories = @user.repositories.paginate(:all, :include => :project, 
      :order => "project_id desc",
      :page => params[:page])
  end

  def create
    @user = User.new(params[:user])
    @user.login = params[:user][:login]
    @user.save!
    redirect_to root_path
    flash[:notice] = "Thanks for signing up! You will receive an account activation email soon"
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def activate
    if user = User.find_by_activation_code(params[:activation_code])
      self.current_user = user
      if logged_in? && !current_user.activated?
        current_user.activate
        flash[:notice] = "Your account has been activated, welcome!"
      end
    else
      flash[:error] = "Invalid activation code"
    end
    redirect_back_or_default('/')
  end

end
