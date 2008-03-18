class SearchesController < ApplicationController
  
  def show
    unless params[:q].blank?
      @search = Ultrasphinx::Search.new({
        :query => params[:q], :page => (params[:page] || 1)
      })
      @search.run
      @results = @search.results
    end
  end
  
end
