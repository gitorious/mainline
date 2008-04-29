class EventsController < ApplicationController
  def index
    @events = Event.paginate(:all, :order => "events.created_at desc", 
                  :page => params[:page], :include => [:user])
    @atom_auto_discovery_url = formatted_events_path(:atom)
    
    respond_to do |if_format_is|
      if_format_is.html {}
      if_format_is.atom {}
    end
  end
  
end
