class EventsController < ApplicationController
  def index
    @events = Event.paginate(:all, :order => "events.date asc", 
                  :page => params[:page], :include => [:action, :user, :target])
  end
  
end
