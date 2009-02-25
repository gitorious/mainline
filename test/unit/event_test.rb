# encoding: utf-8
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


require File.dirname(__FILE__) + '/../test_helper'

class EventTest < ActiveSupport::TestCase

  def setup
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
  
  should " belong to a user or have an author email" do
    event = Event.new(:target => repositories(:johans), :body => 'blabla', :project => @project, :action => Action::COMMIT)
    assert event.user.nil?
    assert !event.valid?, 'valid? should be false'
    event.email = 'foo@bar.com'
    assert event.user.nil?
    assert event.valid?
    assert_equal 'foo@bar.com', event.git_actor.email
  end
  
  should "belong to a user who commits with an aliased email" do
    event = Event.new(:target => repositories(:johans), :body => 'blabla', 
              :project => @project, :action => Action::COMMIT)
    assert_nil event.user
    event.email = emails(:johans1).address
    assert_equal users(:johan), event.user
  end
  
  should "handles setting the actor from a string" do
    event = Event.new
    event.email = "marius@stones.com"
    assert_equal 'marius', event.actor_display
    event = Event.new
    event.email = 'Marius Mathiesen <marius@stones.com>'
    assert_equal 'Marius Mathiesen', event.actor_display
  end
  
  should "provides an actor_display for User objects too" do
    event = Event.new
    user = User.new(:fullname => 'Johan Sørensen', :email => 'johan@johansorensen.com')
    event.user = user
    assert_equal 'Johan Sørensen', event.actor_display
  end
  
  context 'A push event' do
    setup do
      @event = new_event(:action => Action::PUSH)
      assert @event.save
    end
    
    should 'have a method for attaching commit events' do
      commit = @event.build_commit(
        :email  => 'Linus Torvalds <linus@kernel.org>',
        :data   => 'ffc0fa98',
        :body   => 'Adding README')
      assert commit.save
      assert_equal(@event, commit.target)
      assert @event.has_commits?
      assert @event.events.commits.include?(commit)
      assert_equal('commit', commit.kind)
    end
  end
end
