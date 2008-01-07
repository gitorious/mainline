require File.dirname(__FILE__) + '/../spec_helper'

describe Mailer do
  before(:each) do
    Mailer.deliveries = []
  end
  
  it "send new_repository_clone" do
    repos = repositories(:johans2)
    mail = Mailer.create_new_repository_clone(repos)
    
    mail.to.should == [repos.project.user.email]
    mail.subject.should == %Q{[Gitorious] "#{repos.user.login}" has cloned "#{repos.parent.name}"}
    mail.body.should match(/#{repos.user.login} recently created a clone/)
    mail.body.should match(/\/p\/#{repos.project.slug}\/repos\/#{repos.name}/)
    
    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end
  
  it "sends signup_notification" do
    user = users(:johan)
    user.password = "fubar"
    mail = Mailer.create_signup_notification(user)
    
    mail.to.should == [user.email]
    mail.subject.should == "[Gitorious] Please activate your new account"
    mail.body.should match(/users\/activate\/#{user.activation_code}/)
    mail.body.should match(/Username: #{user.login}$/)
    mail.body.should match(/Password: fubar$/)
    
    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end
  
  it "sends activation" do
    user = users(:johan)
    mail = Mailer.create_activation(user)
    
    mail.to.should == [user.email]
    mail.subject.should == "[Gitorious] Your account has been activated!"
    mail.body.should match(/your account has been activated/)
    
    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end

end
