require File.dirname(__FILE__) + '/../spec_helper'

describe LogsHelper do
  
  it "includes the RepostoriesHelper" do
    self.class.ancestors.should  include(RepositoriesHelper)
  end
end
