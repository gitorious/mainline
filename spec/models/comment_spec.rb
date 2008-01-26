require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do
  before(:each) do
    @comment = new_comment
  end
  
  def new_comment(opts={})
    c = Comment.new({
      :repository => repositories(:johans),
      :sha1 => Digest::SHA1.hexdigest("baz"),
      :body => "blabla", 
      :project => projects(:johans)
    }.merge(opts))
    c.user = opts[:user] || users(:johan)
    c
  end
  
  it "should have valid associations" do
    @comment.should have_valid_associations
  end

  it "should have a repository to be valid" do
    @comment.repository = nil
    @comment.should_not be_valid
    @comment.should have(1).error_on(:repository_id)
  end
  
  it "should have a user to be valid" do
    @comment.user_id = nil
    @comment.should_not be_valid
    @comment.should have(1).error_on(:user_id)
  end
  
  it "should have a body to be valid" do
    @comment.body = nil
    @comment.should_not be_valid
    @comment.should have(1).error_on(:body)
  end
  
  it "should belong to a project to be valid" do
    @comment.project_id = nil
    @comment.should_not be_valid
    @comment.should have(1).error_on(:project_id)
  end
  
  # it "should have a sha1 to be valid" do
  #   @comment.sha1 = nil
  #   @comment.should_not be_valid
  #   @comment.should have(1).error_on(:sha1)
  # end
end
