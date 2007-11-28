class KeysController < ApplicationController
  before_filter :login_required
  
  def index
    @ssh_keys = current_user.ssh_keys
  end
  
  def new
    @ssh_key = current_user.ssh_keys.new
  end
  
  def create
    @ssh_key = current_user.ssh_keys.new
    @ssh_key.key = params[:ssh_key][:key]
    if @ssh_key.save
      flash[:notice] = "Key added"
      redirect_to account_path
    else
      render :action => "new"
    end
  end
  
  def show
    @ssh_key = current_user.ssh_keys.find(params[:id])
  end
  
  def edit
    @ssh_key = current_user.ssh_keys.find(params[:id])
  end
  
  def update
    @ssh_key = current_user.ssh_keys.find(params[:id])
    @ssh_key.key = params[:ssh_key][:key]
    if @ssh_key.save
      flash[:notice] = "Key updated"
      redirect_to account_path
    else
      render :action => "new"
    end
  end
  
  def destroy
    @ssh_key = current_user.ssh_keys.find(params[:id])
    if @ssh_key.destroy
      flash[:notice] = "Key removed"
    end
    redirect_to account_path    
  end
end
