class UsersController < ApplicationController
  # render new.rhtml
  def new
  end
  
  def show
    @user = User.find_by_login!(params[:id])
    @projects = @user.projects.find(:all, :include => [:tags, { :repositories => :project }])
    @repositories = @user.repositories.find(:all, :conditions => ["mainline = ?", false])
    @events = @user.events.find(:all, :order => "events.date asc", :include => [:action, :user, :target])
    
    @commits_last_week = 0
    @projects.map{|p| p.repositories.first }.concat(@repositories).each do |repo|
      @commits_last_week += repo.count_commits_from_last_week_by_user(@user)
    end
  end

  def create
    @user = User.new(params[:user])
    @user.login = params[:user][:login]
    @user.save!    
    flash[:notice] = "Thanks for signing up! You will receive an account activation email soon"
    redirect_to root_path
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
