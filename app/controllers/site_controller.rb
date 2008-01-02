class SiteController < ApplicationController
  
  def index
    @tags = Project.tag_counts
  end
  
  def about
  end
  
end
