
require 'gruff'

class ProjectsController < ApplicationController  
  before_filter :login_required, :only => [:create, :update, :destroy, :new]
  before_filter :require_user_has_ssh_keys, :only => [:new, :create]
  
  def index
    @projects = Project.paginate(:all, :order => "projects.created_at desc", 
                  :page => params[:page], :include => [:tags])
    @atom_auto_discovery_url = formatted_projects_path(:atom)
    respond_to do |format|
      format.html { @tags = Project.tag_counts }
      format.xml  { render :xml => @projects }
      format.atom { }
    end
  end
  
  def category
    tags = params[:id].to_s.gsub(/,\ ?/, " ")
    @projects = Project.paginate_by_tag(tags, :order => 'created_at desc', 
                  :page => params[:page])
    @atom_auto_discovery_url = formatted_projects_category_path(params[:id], :atom)
    respond_to do |format|
      format.html do
        @tags = Project.tag_counts
        render :action => "index"
      end
      format.xml  { render :xml => @projects }
      format.atom { render :action => "index"}
    end
  end
  
  def show
    @project = Project.find_by_slug!(params[:id])
    @repositories = @project.repositories
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @project }
    end
  end
  
  def new
  end
  
  def create
    @project = Project.new(params[:project])
    @project.user = current_user
    if @project.save
      redirect_to projects_path
    else
      render :action => 'new'
    end
  end
  
  def edit
    @project = Project.find_by_slug!(params[:id])
  end
  
  def update
    @project = Project.find_by_slug!(params[:id])
    if @project.user != current_user
      flash[:error] = "You're not the owner of this project"
      redirect_to(project_path(@project)) and return
    end
    @project.attributes = params[:project]
    if @project.save
      redirect_to project_path(@project)
    else
      render :action => 'new'
    end
  end
  
  def confirm_delete
    @project = Project.find_by_slug!(params[:id])
  end
  
  def destroy
    @project = Project.find_by_slug!(params[:id])
    if @project.can_be_deleted_by?(current_user)
      @project.destroy
    else
      flash[:error] = "You're not the owner of this project, or the project has clones"
    end
    redirect_to projects_path
  end
  
  def commit_graph
    @project = Project.find_by_slug!(params[:id])
    sha = params[:sha] ? params[:sha] : "master"
    
    repo = @project.mainline_repository
    git_repo = repo.git
    git = git_repo.git
    
    width = params[:width] ? params[:width].to_i : 250
    
    h = Hash.new
    dategroup = Date.new
    
    data = git.rev_list({:pretty => "format:%aD", :since => "24 weeks ago"}, sha)
    data.each_line { |line|
      if line =~ /\d\d:\d\d:\d\d/ then
        date = Date.parse(line)
        
        dategroup = Date.new(date.year, date.month, 1)
        if h[dategroup]
          h[dategroup] += 1
        else
          h[dategroup] = 1
        end
      end
    }
    
    g = Gruff::Line.new(width)
    setup_gruff(g)
    g.hide_legend = true
    g.title = "#{@project.title} commits" 
    
    commits = []
    labels = {}
    it = 0
    h.sort.each { |entry|
      date = entry.first
      value = entry.last
      
      labels[it] = date.strftime("%m/%y")
      commits << value
      it+=1
    }
    
    unless commits.empty?
      g.data("Commits", commits)
      g.labels = labels
#       g.labels = { 0 => labels.first, commits.size-1 => labels.last } 
    end
    
    send_data(g.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "#{@project.slug}-commits.png")
  end
  
  def commit_graph_by_author
    @project = Project.find_by_slug!(params[:id])
    sha = params[:sha] ? params[:sha] : "master"
    
    repo = @project.mainline_repository
    git_repo = repo.git
    git = git_repo.git
    
    width = params[:width] ? params[:width].to_i : 400
    
    h = Hash.new
    
    data = git.rev_list({:pretty => "format:name:%cn", :since => "1 years ago" }, sha)
    data.each_line { |line|
      if line =~ /^name:(.*)$/ then
        author = $1
        
        if h[author]
          h[author] += 1
        else
          h[author] = 1
        end
      end
    }
    
    g = Gruff::Pie.new(width)
    setup_gruff(g)
    g.title = "#{@project.title}" 
    
    sorted = h.sort_by { |author, commits|
      commits
    }
    
    label_it = 0
    labels = {}
    max = 5
    others = []
    top = sorted
    
    if sorted.size > max
      top = sorted[sorted.size-max, sorted.size]
      others = sorted[0, sorted.size-max]
    end
    
    top.each { |entry|
      v = entry.last
      g.data(entry.first, [v])
      
      labels[label_it] = v
      label_it += 1
    }
    
    unless others.empty?
      others_v = others.inject { |v, acum| [v.last + acum.last] }
      labels[label_it] = others_v.first
      g.data("others", others_v )
    end
    
    g.labels = labels
    
    send_data(g.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "#{@project.slug}-commits_author.png")
  end
  
  private
  def setup_gruff(g)
    g.no_data_message = "No commits" 
    
    colors = [
      '#a9dada', # blue
      '#aedaa9', # green
      '#dadaa9', # yellow
      '#daaea9', # peach
      '#a9a9da', # dk purple
      '#daaeda', # purple
      '#dadada' # grey
    ]
    
    g.theme = {
      :colors => colors,
      :marker_color => '#aea9a9', # Grey
      :font_color => 'black',
      :background_colors =>  '#efefef'
    }
    
    g
  end
end