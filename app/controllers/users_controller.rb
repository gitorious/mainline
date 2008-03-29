class UsersController < ApplicationController
  # render new.rhtml
  def new
  end
  
  def show
    @user = User.find_by_login!(params[:id])
    @projects = @user.projects.find(:all, :include => [:tags, { :repositories => :project }])
    @repositories = @user.repositories.find(:all, :conditions => ["mainline = ?", false])
    
    @commits_last_week = 0
    @projects.each { |project|
      @commits_last_week += commits_last_week(@user, project.repositories.first)
    }
    
    @repositories.each { |repo|
      @commits_last_week += commits_last_week(@user, repo)
    }
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
  
  protected
  def commits_last_week(user, repo)
    return 0 unless repo.has_commits?
    git_repo = repo.git
    git = git_repo.git
    
    h = Hash.new
    
    data = git.rev_list({:pretty => "format:email:%ce", :since => "last week" }, "master")
    
    user_email = user.email
    count = 0
    data.each_line { |line|
      if line =~ /email:(.*)$/
        count += 1 if user_email == $1
      end
    }
    
    count
  end
end
