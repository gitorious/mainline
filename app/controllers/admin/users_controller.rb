class Admin::UsersController < ApplicationController
  before_filter :login_required
  before_filter :check_admin
  
  def index
    @users = User.paginate(:all, :order => 'suspended_at, login', 
                            :page => params[:page])
    respond_to do |wants|
      wants.html
    end
  end
  
  def new
    @user = User.new
    respond_to do |wants|
      wants.html
    end
  end
  
  def create
    @user = User.new(params[:user])
    @user.login = params[:user][:login]
    @user.is_admin = params[:user][:is_admin] == "1"
    respond_to do |wants|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        wants.html { redirect_to(admin_users_path) }
        wants.xml { render :xml => @user, :status => :created, :location => @user }
      else
        wants.html { render :action => "new" }
        wants.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  
  def suspend
    @user = User.find_by_login!(params[:id])
    @user.suspended_at = Time.now
    if @user.save
      flash[:notice] = "User #{@user.login} was successfully suspended."
    else
      flash[:error] = "Unable to suspend user #{@user.login}."
    end
    redirect_to admin_users_url()
  end
  
  def unsuspend
    @user = User.find_by_login!(params[:id])
    @user.suspended_at = nil
    if @user.save
      flash[:notice] = "User #{@user.login} was successfully unsuspended."
    else
      flash[:error] = "Unable to unsuspend user #{@user.login}."
    end
    redirect_to admin_users_url()
  end
  
  private
  
  def check_admin
    unless current_user.admin?
      flash[:error] = "For Administrators Only"
      redirect_to root_path
    end
  end
end
