require File.dirname(__FILE__) + '/../test_helper'

class EmailTest < ActiveSupport::TestCase
  should_belong_to :user
  
  should_validate_presence_of :address
  should_not_allow_values_for :address, "kernel.wtf", "you@host"
  should_allow_values_for :address, "johan@example.com", "ker+nel.w-t-f@foo-bar.co.uk"
  should_ensure_length_in_range(:address, 5..255)
  should_validate_uniqueness_of :address, :scoped_to => "user_id", :case_sensitive => false
  
  should "default to a pending state" do
    e = Email.create!(:address => "foo@bar.com", :user => users(:johan))
    assert e.pending?
    e.confirm!
    assert e.confirmed?
  end
  
  should "send an email confirmation on create" do
    email = Email.new(:address => "foo@bar.com", :user => users(:johan))
    Mailer.expects(:deliver_new_email_alias).with(email).returns(true)
    email.save!
  end
  
  should "set a confirmation_code on create" do
    email = Email.create!(:address => "foo@bar.com", :user => users(:johan))
    assert_match /^[a-z0-9]{40}$/, email.confirmation_code
  end
  
  should "confirm an email adress" do
    email = Email.create!(:address => "foo@bar.com", :user => users(:johan))
    email.confirm!
    assert_nil email.confirmation_code
  end
end
