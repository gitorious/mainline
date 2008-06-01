require File.dirname(__FILE__) + '/../spec_helper'

describe LogsHelper do
  
  it "includes the RepostoriesHelper" do
    included_modules = (class << helper; self; end).send(:included_modules)
    included_modules.should  include(RepositoriesHelper)
  end
end
