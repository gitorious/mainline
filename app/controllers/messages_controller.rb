class MessagesController < ApplicationController
  before_filter :login_required
  
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
  end

  def create
    @message = Message.new(params[:message])
    @message.sender = current_user
    recipient = User.find_by_login(params[:recipient][:login])
    @message.recipient = recipient
    if @message.save
      flash[:notice] = "Your message was sent"
      redirect_to :action => :index
    else
      render :action => :new
    end
  end
  
  def new
    @message = Message.new
  end
  
  # POST /messges/<id>/reply
  def reply
    original_message = current_user.received_messages.find(params[:id])
    @message = original_message.build_reply(params[:message])
    original_message.read! unless original_message.read?
    if @message.save
      flash[:notice] = "Your reply was sent"
      redirect_to :action => :index
    else
      flash[:error] = "Your message could not be sent"
      redirect_to :action => :index
    end
  end
  
  def auto_complete_for_recipient_login
    login = params[:recipient][:login]
    @users = User.find(:all, 
      :conditions => [ 'LOWER(login) LIKE ?', '%' + login.downcase + '%' ],
      :limit => 10)
    render :layout => false
  end
end
