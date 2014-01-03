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

require 'event_presenter'
require 'event_presenter/push_summary_event'

class EventPresenter::PushSummaryEventTest < ActiveSupport::TestCase
  include ViewContextHelper

  should "sanitizes commit message" do
    repository = repositories(:johans)
    body = "I'm an <script>tag</script>"
    event = Event.new(target: repository, action: Action::COMMIT, body: body, data: 1)
    presenter = EventPresenter::CommitEvent.new(event, view_context)

    assert_include presenter.body, "&lt;script&gt;tag&lt;/script&gt;"
  end
end
