# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious
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

class UserAdministrationTest < ActiveSupport::TestCase
  include Gitorious::UserAdministration

  should "summarize operations for feedback in CLI or GUI" do
    summary = suspend_user(User.new)
    assert summary.length > 0
    assert summary.class == String
    assert summary =~ /Suspended Gitorious account/
  end

  context "team cleanup" do
    setup do
      @g = groups(:team_thunderbird) # Already has Mike 
      @user = users(:johan)      
      @g.add_member(@user, Role.admin)
    end

    should "remove user from all his current teams" do
      assert_equal 2, @g.members.size
      remove_from_teams(@user)
      @g.reload
      assert_equal 1, @g.members.size
    end

    should "report which teams user has been removed from" do
      summary = remove_from_teams(@user)
      assert summary =~ /Removed user from team\(s\): team-thunderbird, a-team/
    end
  end

  context "committership cleanup" do
    setup do
      @r1  = repositories(:johans)
      @r2 = repositories(:moes)
      @user = users(:mike)

      c = @r1.committerships.new
      c.creator = @user
      c.committer = @user
      c.build_permissions :review, :admin, :commit 
      c.save
    end

    should "remove the users committerships" do
      assert_equal 2, @r1.committerships.size
      assert_equal 1, @r2.committerships.size
      remove_committerships(@user)
      assert_equal 1, @r1.committerships.size
      assert_equal 1, @r2.committerships.size
    end

    should "report repos where committerships were deleted" do
      summary = remove_committerships(@user)
      assert summary =~ /Removed user committerships from repo\(s\): johansprojectrepos/
    end
  end

  context "reporting on orphaned teams" do
    setup do
      @user = users(:johan)
      @g1 = groups(:a_team) # Johan is sole admin in this one
      @g2 = groups(:team_thunderbird) # Mike is admin as well in this one
      @g2.add_member(@user, Role.admin)
    end

    should "build list of teams which are orphaned if user leaves" do
      orphans = teams_orphaned_by_user_leaving(@user)
      assert sole_admin?(users(:johan), @g1)
      assert !sole_admin?(users(:johan), @g2)
      assert_equal 1, orphans.size
      assert orphans.include?(@g1)
      assert !orphans.include?(@g2)
    end
  end

  context "reporting on orphaned projects" do
    setup do
      @user = users(:johan)
      @johans_project = projects(:johans)
      @johans_project.owner = @user
      @johans_project.save
      @other_project = projects(:johans)
    end
    
    should "build list of projects which are orphaned if user leaves" do
      orphans = projects_orphaned_by_user_leaving(@user)
      assert orphans.all?{|p| p.owner.id == @user.id}
    end
  end  
end
