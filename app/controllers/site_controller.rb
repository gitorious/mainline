class SiteController < ApplicationController
  
  def index
    @tags = Project.tag_counts
    @projects = Project.find(:all, :limit => 5, :order => "id desc")
  end
  
  def about
  end
  
end
