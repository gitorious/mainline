class KeysController < ApplicationController
  before_filter :login_required
  
  def index
    @ssh_keys = current_user.ssh_keys
    respond_to do |format|
      format.html
      format.xml { render :xml => @ssh_keys }
    end
  end
  
  def new
    @ssh_key = current_user.ssh_keys.new
  end
  # respond_to do |format|
  #   if @event.save
  #     flash[:notice] = 'Event was successfully created.'
  #     format.html { redirect_to(@event) }
  #     format.xml  { render :xml => @event, :status => :created, :location => @event }
  #   else
  #     format.html { render :action => "new" }
  #     format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
  #   end
  def create
    @ssh_key = current_user.ssh_keys.new
    @ssh_key.key = params[:ssh_key][:key]
    
    respond_to do |format|
      if @ssh_key.save
        flash[:notice] = "Key added"
        format.html { redirect_to account_path }
        format.xml  { render :xml => @ssh_key, :status => :created, :location => account_key_path(@ssh_key) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @ssh_key.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    @ssh_key = current_user.ssh_keys.find(params[:id])
    
    respond_to do |format|
      format.html
      format.xml { render :xml => @ssh_key }
    end
  end

  # can't update keys since yet we'd have to to search/replace through 
  # authorized_keys
  # def edit
  #   @ssh_key = current_user.ssh_keys.find(params[:id])
  # end
  # 
  # def update
  #   @ssh_key = current_user.ssh_keys.find(params[:id])
  #   @ssh_key.key = params[:ssh_key][:key]
  #   if @ssh_key.save
  #     flash[:notice] = "Key updated"
  #     redirect_to account_path
  #   else
  #     render :action => "new"
  #   end
  # end
  
  def destroy
    @ssh_key = current_user.ssh_keys.find(params[:id])
    if @ssh_key.destroy
      flash[:notice] = "Key removed"
    end
    redirect_to account_path    
  end
end
