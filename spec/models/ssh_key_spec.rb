require File.dirname(__FILE__) + '/../spec_helper'

describe SshKey do
  
  def create_key(opts={})
    SshKey.new({
      :user_id => 1,
      :key => "ssh-rsa bXljYWtkZHlpemltd21vY2NqdGJnaHN2bXFjdG9zbXplaGlpZnZ0a3VyZWFz\nc2dkanB4aXNxamxieGVib3l6Z3hmb2ZxZW15Y2FrZGR5aXppbXdtb2NjanRi\nZ2hzdm1xY3Rvc216ZWhpaWZ2dGt1cmVhc3NnZGpweGlzcWpsYnhlYm95emd4\nZm9mcWU= foo@example.com",
    })
  end

  it "should have a valid ssh key" do
    key = create_key
    key.key = ""
    key.should_not be_valid
    key.key = "foo bar@baz"
    key.should_not be_valid
    
    key.key = "ssh-rsa asdasdasdasd bar@baz"
    key.should be_valid
  end
  
  it "should have a user to be valid" do
    key = create_key
    key.user_id = nil
    key.should_not be_valid
    
    key.user_id = users(:johan).id
    key.valid?
    key.should be_valid
  end
end
