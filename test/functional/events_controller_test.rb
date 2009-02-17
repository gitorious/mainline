# encoding: utf-8
#--
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008-2009 Johan Sørensen <johan@johansorensen.com>
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

class EventsControllerTest < ActionController::TestCase

  def setup
    @project = projects(:johans)
    @repository = repositories(:johans)
  end
  
  context "#index" do
    should "shows news" do
      @project.create_event(Action::CREATE_PROJECT, @project, users(:johan), "", "")
      get :index
      assert_response :success
      assert_equal 1, assigns(:events).size
    end
  end
  
  context '#children' do
    setup do
      @push_event = @project.create_event(Action::PUSH, @repository, User.first, "", "A push event", 10.days.ago)
      10.times do |n|
#(:email => c.email, :body => c.message, :data => c.identifier)
        c = @push_event.build_commit(:email => 'John Doe <john@doe.org>', :body => "Commit number #{n}", :data => "ffc0#{n}")
        c.save
      end
    end
    should 'show commits under a push event' do
      get :commits, :id => @push_event.to_param, :format => 'js'
      assert_response :success
    end
  end
end
