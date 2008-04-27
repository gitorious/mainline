class UsersController < ApplicationController
  # render new.rhtml
  def new
  end
  
  def show
    @user = User.find_by_login!(params[:id])
    @projects = @user.projects.find(:all, :include => [:tags, { :repositories => :project }])
    @repositories = @user.repositories.find(:all, :conditions => ["mainline = ?", false])
    @events = @user.events.paginate(:all, 
      :page => params[:page],
      :order => "events.created_at desc", 
      :include => [:user, :project])
    
    @commits_last_week = @user.events.count(:all, 
      :conditions => ["created_at > ? AND action = ?", 7.days.ago, Action::COMMIT])
    @atom_auto_discovery_url = formatted_user_path(@user, :atom)
    
    respond_to do |format|
      format.html { }
      format.atom { }
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
  
  def forgot_password
  end
    
  def reset_password
    if params[:user] && user = User.find_by_email(params[:user][:email])
      # FIXME: should really be a two-step process: receive link, visiting it resets password
      generated_password = user.reset_password!
      Mailer.deliver_forgotten_password(user, generated_password)
      flash[:notice] = "A new password has been sent to your email"
      redirect_to(root_path)
    else
      flash[:error] = "Invalid email"
      redirect_to forgot_password_users_path
    end
  end
end
