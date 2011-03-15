# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

class EventRenderingHelperTest < ActionView::TestCase
  include ApplicationHelper

  context "create tag events" do
    should "link to the tag tree" do
      repository = repositories(:johans)
      event = Event.new
      event.target = repository
      event.data = "v2.19-rc3"
      event.body = "Created tag v2.19-rc3"

      action, body, category = render_event_create_tag(event)

      assert_equal "<a href=\"/johans-project/johansprojectrepos/trees/v2.19-rc3\">v2.19-rc3: Created tag v2.19-rc3</a>", body
    end
  end
end
