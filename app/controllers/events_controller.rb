class EventsController < ApplicationController
  def index
    @events = Event.paginate(:all, :order => "events.created_at asc", 
                  :page => params[:page], :include => [:user])
  end
  
end
