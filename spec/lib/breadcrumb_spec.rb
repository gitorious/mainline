#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe Breadcrumb::Folder do
  before(:each) do
    @head = Object.new
    def @head.name
      return "head"
    end
    @folder = Breadcrumb::Folder.new(:paths => %w(foo bar baz), :head => @head, :repository => nil)
  end
  
  it 'should return a relevant title' do
    @folder.title.should == 'baz'
  end
  
  it 'should return parents all the way up to a Branch' do
    branch = @folder.breadcrumb_parent.breadcrumb_parent.breadcrumb_parent.breadcrumb_parent
    branch.should be_a(Breadcrumb::Branch)
  end
  
  describe "a top level folder" do
    folder = Breadcrumb::Folder.new(:paths => [], :head => @head, :repository => nil)
    folder.title.should == '/'
  end
end



describe Breadcrumb::Branch do
  before(:each) do
    @o = Object.new
    def @o.name
      return "Yikes"
    end
    @branch = Breadcrumb::Branch.new(@o, 'I am a parent')
  end
  
  it 'should return its title' do
    @branch.title.should == 'Yikes'
  end
  
  it 'should return its parent' do
    @branch.breadcrumb_parent.should == "I am a parent"
  end
end

describe Breadcrumb::Blob do
  before(:each) do
    @blob = Breadcrumb::Blob.new(:paths => %w(foo), :name => 'README', :head => nil ,:repository => nil)
  end
  
  it 'should have a Folder as its parent' do
    @blob.breadcrumb_parent.should be_a(Breadcrumb::Folder)
  end
  
  it 'should keep its path' do
    @blob.path.should == %w(foo)
  end
end

describe Breadcrumb::Commit do
  before(:each) do
    @repo = mock
    @commit = Breadcrumb::Commit.new(:repository => @repo, :id => 'ffc0349')
  end
  
  it 'should return its title' do
    @commit.title.should == 'ffc0349'
  end
  
  it 'should return the Repository as its parent' do
    @commit.breadcrumb_parent.should == @repo
  end
end

describe Breadcrumb::Page do
  before(:each) do
    project = mock
    page = mock
    page.stubs(:title).returns('Home')
    @page = Breadcrumb::Page.new(page, project)
  end
  
  it 'should return a Wiki as its parent' do
    @page.breadcrumb_parent.should be_a(Breadcrumb::Wiki)
  end
  
  it 'should return its title' do
    @page.title.should == 'Home'
  end
end

describe Breadcrumb::Memberships do
  before(:each) do
    @group = mock("Group")
    @crumb = Breadcrumb::Memberships.new(@group)
  end
  
  it 'should return a Froup as its parent' do
    @crumb.breadcrumb_parent.should == @group
  end
  
  it 'should return its title' do
    @crumb.title.should == 'Members'
  end
end

describe Breadcrumb::Participations do
  before(:each) do
    @repo = mock("Repostitory")
    @crumb = Breadcrumb::Participations.new(@repo)
  end
  
  it 'should return a Froup as its parent' do
    @crumb.breadcrumb_parent.should == @repo
  end
  
  it 'should return its title' do
    @crumb.title.should == 'Commit teams'
  end
end