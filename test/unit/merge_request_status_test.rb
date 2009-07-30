# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class MergeRequestStatusTest < ActiveSupport::TestCase
  
  should_belong_to :project
  should_validate_presence_of :project, :state, :name

  context "State" do
    setup { @status = MergeRequestStatus.new(:project => Project.first, :name => "foo") }

    should "be open? when the state is open" do
      @status.state = MergeRequest::STATUS_OPEN
      assert @status.open?
      assert !@status.closed?
    end

    should "be closed? when the state is closed" do
      @status.state = MergeRequest::STATUS_CLOSED
      assert !@status.open?
      assert @status.closed?
    end
  end  
end
