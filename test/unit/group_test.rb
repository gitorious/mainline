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

class GroupTest < ActiveSupport::TestCase
  
  context "in general" do
    should "uses the name as to_param" do
      group = Factory.build(:group)
      assert_equal group.name, group.to_param
    end
  end
  
  context "members" do
    setup do
      @johan = Factory.create(:user)
      @mike = Factory.create(:user)
      @group = groups(:team_thunderbird)
      @group.add_member(@mike, Role.admin)
    end
    
    should "knows if a user is a member" do
      assert !@group.member?(@johan), '@group.member?(@johan) should be false'
      assert @group.member?(@mike), '@group.member?(@mike) should be true'
    end
    
    should "know the role of a member" do
      assert_nil @group.role_of_user(@johan)
      assert_equal roles(:admin), @group.role_of_user(@mike)
      assert !@group.admin?(@johan), '@group.admin?(@johan) should be false'
      assert @group.admin?(@mike), '@group.admin?(@mike) should be true'
      
      assert !@group.committer?(@johan), '@group.committer?(@johan) should be false'
      assert @group.committer?(@mike), '@group.committer?(@mike) should be true'
    end
    
    should "can add a user with a role using add_member" do
      assert !@group.member?(@johan), '@group.member?(@johan) should be false'
      @group.add_member(@johan, Role.member)
      assert @group.reload.member?(@johan), '@group.reload.member?(@johan) should be true'
    end
  end
  
  context "Committerships" do
    setup do
      @group = groups(:team_thunderbird)
    end
    
    should "has a committership with a repository" do
      assert_equal repositories(:moes), committerships(:thunderbird_moes).repository
      assert_equal groups(:team_thunderbird), committerships(:thunderbird_moes).committer
      assert @group.participated_repositories.include?(repositories(:moes))
    end
  end
  
  should "has a collection of project ids, of all projects it is somehow associated with" do
    group = groups(:team_thunderbird)
    assert group.all_related_project_ids.include?(projects(:thunderbird).id)
    assert group.all_related_project_ids.include?(repositories(:johans2).project_id)
    assert group.all_related_project_ids.include?(projects(:moes).id)
  end
  
  context "repositories" do
    should "has many repositories" do
      assert groups(:team_thunderbird).repositories.include?(repositories(:johans2))
    end
    
    should "not have wiki repositories in #repositories" do
      wiki = repositories(:johans_wiki)
      wiki.owner = groups(:team_thunderbird)
      wiki.save!
      assert !groups(:team_thunderbird).repositories.include?(wiki)
    end
  end
  
  should "has to_param_with_prefix" do
    grp = Factory.build(:group, :name => 'webkit')
    assert_equal "+#{grp.to_param}", grp.to_param_with_prefix
  end
  
  should "has no breadcrumb parent" do
    assert_equal nil, Factory.build(:group).breadcrumb_parent
  end
  
  context 'Deleting groups' do
    setup do
      @group = Factory.create(:group)
    end

    should "be possible if 1 member or less" do
      Factory.create(:membership, :group => @group)
      assert_equal 1, @group.members.count
      assert @group.deletable?
      Factory.create(:membership, :group => @group)
      assert !@group.deletable?
    end

    should 'not be possible if associated projects exist' do
      assert_equal [], @group.projects
      assert @group.deletable?
      project = Factory.create(:project, :owner => @group, :user => @group.creator)
      assert_equal [project], @group.projects.reload
      assert !@group.deletable?
    end
  end
  
  context "validations" do
    setup {@existing_group = Factory.create(:group)}
    
    should " have a unique name" do
      group = Group.new({
        :name => @existing_group.name
      })
      assert !group.valid?, 'valid? should be false'
      assert_not_nil group.errors.on(:name)
    end
    
    should " have a alphanumeric name" do
      group = Factory.build(:group, :name => "fu bar")
      assert !group.valid?, 'group.valid? should be false'
      assert_not_nil group.errors.on(:name)
    end

    should 'require valid names' do
      ['foo_bar', 'foo.bar', 'foo bar'].each do |name|
        g = Group.new
        g.name = name
        assert !g.save
        assert_not_nil(g.errors.on(:name), "#{name} should not be a valid name")
      end
    end
    
    should 'automatically downcase the group name before validation' do
      g = Factory.create(:group, :name => 'FooWorkers')
      assert_equal('fooworkers', g.name)
    end
  end
  
  context 'Avatars' do
    setup { @group = Factory.create(:group) }
    
    should 'have a default avatar' do
      assert_equal '/images/default_group_avatar.png', @group.avatar.url
    end
    
    should 'use the correct path when an avatar is set' do
      @group.avatar_file_name = 'foo.png'
      assert_equal "/system/group_avatars/#{@group.name}/original/foo.png", @group.avatar.url
    end
  end
  
  should "not include duplicates in all_participating_in_projects" do
    group = groups(:team_thunderbird)
    r = projects(:johans).repositories.mainlines.first
    r.owner = group
    r.save!
    projects(:moes).repositories.create!({
      :name => "mainline2",
      :owner => group,
      :user => projects(:johans).user,
    })
    assert_equal [group], Group.all_participating_in_projects(projects(:johans, :moes))
  end
end
