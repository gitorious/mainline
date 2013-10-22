#repository.inspect encoding: utf-8
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

class UpdateProjectTest < ActiveSupport::TestCase
  setup do
    project = projects(:johans)
    user = users(:johan)

    @update_project = UpdateProject.new(user, project)
    @default_id = project.merge_request_statuses.find(&:default).id
    @other_id = project.merge_request_statuses.reject(&:default).first.id
  end

  should "not allow removing the default merge request status" do
    outcome = @update_project.execute(
      :default_merge_request_status_id => @default_id,
      :merge_request_statuses_attributes => {
        0 => {:id => @default_id, :_destroy => true}
      }
    )

    refute outcome.success?
  end

  should "validate merge_request_statuses" do
    outcome = @update_project.execute(
      :default_merge_request_status_id => @default_id,
      :merge_request_statuses_attributes => {
        0 => {:id => @default_id, :_destroy => false},
        1 => {:id => @other_id, :_destroy => false},
        123212132133 => {:name => 'fooo', :_destroy => false}
      }
    )

    refute outcome.success?
  end

  should "allow removing the default merge request status if another one is chosen as the default" do
    outcome = @update_project.execute(
      :default_merge_request_status_id => @other_id,
      :merge_request_statuses_attributes => {
        0 => {:id => @default_id, :_destroy => true},
        1 => {:id => @other_id, :_destroy => false}
      }
    )

    assert outcome.success?
  end

  should "save wiki settings" do
    outcome = @update_project.execute(:wiki_permissions => 1)

    assert outcome.success?
    assert_equal projects(:johans).reload.wiki_permissions, 1
  end
end
