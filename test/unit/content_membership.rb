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

require "test_helper"

class ContentMembershipTest  < ActiveSupport::TestCase
  should validate_presence_of(:member_id)
  should validate_presence_of(:content_id)

  context 'ContentMembership uniqueness' do
    should 'not allow the same user to be added twice to a project' do
      project = projects(:johans)
      user = users(:moe)

      project.content_memberships.create!(:member => user)
      duplicate_membership = project.content_memberships.new(:member => user)

      refute duplicate_membership.valid?
    end

    should 'allow the same user to be added to multiple projects' do
      project = projects(:johans)
      other_project = projects(:thunderbird)
      user = users(:moe)

      project.content_memberships.create!(:member => user)
      assert other_project.content_memberships.new(:member => user).valid?
    end
  end
end
