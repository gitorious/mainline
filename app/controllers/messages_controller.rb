class MessagesController < ApplicationController
  before_filter :login_required
  renders_in_global_context
  
  def index
    @messages = current_user.top_level_messages.paginate(:page => params[:page])
    @root = Breadcrumb::ReceivedMessages.new
  end
  
  def sent
    @messages = current_user.sent_messages.paginate(:all,
      :page => params[:page])
    @root = Breadcrumb::SentMessages.new
  end
  
  def read
    @message = current_user.received_messages.find(params[:id])
    @message.read!
    respond_to do |wants|
      wants.js
    end
  end
  
  def show
    @message = Message.find(params[:id])
    unless @message.sender == current_user or @message.recipient == current_user
      raise ActiveRecord::RecordNotFound and return
    end
    @message.read! if !@message.read? and @message.recipient == current_user
    respond_to do |wants|
      wants.html
      wants.js {render :partial => "message", :layout => false}
    end
  end

  def create
    thread_options = params[:message].merge({:recipients => params[:recipient][:login], :sender => current_user})
    logger.debug(thread_options)
    @messages = MessageThread.new(thread_options)
    if @messages.save
      flash[:notice] =  "#{@messages.title} sent"
      redirect_to :action => :index
    else
      @message = @messages.message
      render :action => :new
    end
  end
  
  def new
    @message = Message.new
  end
  
  # POST /messages/<id>/reply
  def reply
    original_message = current_user.received_messages.find(params[:id])
    @message = original_message.build_reply(params[:message])
    original_message.read! unless original_message.read?
    if @message.save
      flash[:notice] = "Your reply was sent"
      redirect_to :action => :show, :id => original_message
    else
      flash[:error] = "Your message could not be sent"
      redirect_to :action => :index
    end
  end
  
  def auto_complete_for_recipient_login
    login = params[:recipient][:login]
    @users = User.find(:all, 
      :conditions => [ 'LOWER(login) LIKE ?', '%' + login.downcase + '%' ],
      :limit => 10).reject{|u|u == current_user}
    render :layout => false
  end
end
