# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "test_helper"

class StatusTagTest < ActiveSupport::TestCase
  def setup
    @project = Project.first
    @project.merge_request_statuses.destroy_all
    @open_status = MergeRequestStatus.create!({
        :project => @project,
        :name => "Open",
        :state => MergeRequest::STATUS_OPEN,
        #:description => "open for business",
        :color => "#ffccff"
      })
    @closed_status = MergeRequestStatus.create!({
        :project => @project,
        :name => "Closed",
        :state => MergeRequest::STATUS_CLOSED,
        :color => "#ccc"
      })
  end

  should "initialize with a name and project" do
    st = StatusTag.new("Fubar", @project)
    assert_equal "Fubar", st.name
    assert_equal @project, st.project
  end

  should "find a MergeRequestStatus if one exist" do
    st = StatusTag.new("Open", @project)
    assert_equal @open_status, st.status
  end

  should "have a description from the MergeRequestStatus" do
    st = StatusTag.new("Open", @project)
    assert_equal @open_status.description, st.description
  end

  should "return nil as description if there is no #status" do
    st = StatusTag.new("Foo", @project)
    assert_nil st.description
  end

  should "have a color from the MergeRequestStatus" do
    st = StatusTag.new("Open", @project)
    assert_equal @open_status.color, st.color
  end

  should "have a default grayish color whe there is no #status" do
    st = StatusTag.new("Foo", @project)
    assert_equal "#cccccc", st.color

    @open_status.update_attribute(:color, "")
    st = StatusTag.new("Foo", @project)
    assert_equal "#cccccc", st.color
  end

  should "know if it is open or closed" do
    st = StatusTag.new("Open", @project)
    assert st.open?
    assert !st.closed?

    st = StatusTag.new("Closed", @project)
    assert st.closed?
    assert !st.open?

    st = StatusTag.new("Foo", @project)
    assert !st.open?
    assert !st.closed?
    assert st.unknown_state?
  end

  should "have a #to_s that is the name" do
    st = StatusTag.new("In Progress", @project)
    assert_equal "In Progress", st.to_s
  end
end
