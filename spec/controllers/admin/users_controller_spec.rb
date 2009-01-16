require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UsersController do
  integrate_views
  
  before(:each) do 
    login_as :johan
  end
  
  it "GET /admin/users" do
    get :index
    response.should be_success
    response.body.should match(/Create New User/)
  end
  
  it "GET /admin/users/new" do
    get :new
    response.should be_success
    response.body.should match(/Is Administrator/)
  end

  it "POST /admin/users" do
    proc {
      post :create, :user => valid_admin_user
    }.should change(User, :count)    
    response.should redirect_to(admin_users_path)
    flash[:error].should be(nil)
  end

  it "PUT /admin/users/1/suspend" do
    users(:johan).suspended_at.should be(nil)
    put :suspend, :id => users(:johan).to_param
    assigns(:user) == users(:johan)
    users(:johan).reload
    users(:johan).suspended_at.should_not be(nil)
    response.should be_redirect
    response.should redirect_to(admin_users_url)
  end

  it "PUT /admin/users/1/unsuspend" do
    users(:johan).suspended_at = Time.new
    users(:johan).save
    put :unsuspend, :id => users(:johan).to_param
    assigns(:user) == users(:johan)
    users(:johan).reload
    users(:johan).suspended_at.should be(nil)
    response.should be_redirect
    response.should redirect_to(admin_users_url)
  end

  it "should not access administrator pages if not admin" do
    login_as :mike
    get :index
    response.should redirect_to(root_path)
    flash[:error].should == "For Administrators Only"
    get :new
    response.should redirect_to(root_path)
    flash[:error].should == "For Administrators Only"
  end
  
  describe "#reset_password" do
    it "redirects to forgot_password if nothing was found" do
      post :reset_password, :user => {:email => "xxx"}
      response.should redirect_to(admin_users_path)
      flash[:error].should match(/invalid email/i)
    end
    
    it "sends a new password if email was found" do
      u = users(:johan)
      User.expects(:generate_random_password).returns("secret")
      Mailer.expects(:deliver_forgotten_password).with(u, "secret")
      post :reset_password, :user => {:email => u.email}
      response.should redirect_to(admin_users_path)
      flash[:notice].should == "A new password has been sent to your email"
      
      User.authenticate(u.email, "secret").should_not be_nil
    end
  end
  
  
  def valid_admin_user
    { :login => 'johndoe', :email => 'foo@foo.com', :password => 'johndoe', :password_confirmation => 'johndoe', :is_admin => "1" }
  end
end
