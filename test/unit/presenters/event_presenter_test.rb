# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

require 'test_helper'
require 'minitest/spec'

require 'event_presenter'
require 'event_presenter/create_project_event'

describe EventPresenter do
  let(:view)  { mock }
  let(:event) { stub(:action_name => 'create project', :data => '') }
  let(:event_presenter) { EventPresenter.build(event, view) }

  describe 'build' do
    it 'creates instance using correct class derived from "action"' do
      assert_instance_of EventPresenter::CreateProjectEvent, event_presenter
    end
  end
end
