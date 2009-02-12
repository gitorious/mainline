#--
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

describe Event do
  before(:each) do
    @event = new_event
    @user = users(:johan)
    @repository = repositories(:johans)
    @project = @repository.project
  end
  
  def new_event(opts={})
    c = Event.new({
      :target => repositories(:johans),
      :body => "blabla"
    }.merge(opts))
    c.user = opts[:user] || users(:johan)
    c.project = opts[:project] || @project
    c
  end
  
  it "should have valid associations" do
    @event.should have_valid_associations
  end  
  
  it 'should belong to a user or have an author email' do
    event = Event.new(:target => repositories(:johans), :body => 'blabla', :project => @project, :action => Action::COMMIT)
    event.user.should be_nil
    event.should_not be_valid
    event.email = 'foo@bar.com'
    event.user.should be_nil
    event.should be_valid
    event.git_actor.email.should == 'foo@bar.com'
  end
  
  it 'handles setting the actor from a string' do
    event = Event.new
    event.email = "marius@stones.com"
    event.actor_display.should == 'marius'
    event = Event.new
    event.email = 'Marius Mathiesen <marius@stones.com>'
    event.actor_display.should == 'Marius Mathiesen'
  end
  
  it 'provides an actor_display for User objects too' do
    event = Event.new
    user = User.new(:fullname => 'Johan Sørensen', :email => 'johan@johansorensen.com')
    event.user = user
    event.actor_display.should == 'Johan Sørensen'
  end
end

