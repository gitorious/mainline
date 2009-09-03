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

class MergeRequestVersionsControllerTest < ActionController::TestCase
  should_render_in_site_specific_context
  context 'Viewing diffs' do
    setup do
      @version = mock
      @merge_request = mock
      @merge_request.stubs(:target_repository).returns(:foo)
      @version.stubs(:merge_request).returns(@merge_request)
      MergeRequestVersion.stubs(:find).returns(@version)
    end
    
    context 'Viewing the diff for a single commit' do
      setup do
        @version.expects(:commits).with("ffcab").returns([])
        get :show, :id => @version, :commit_shas => "ffcab"
      end      
      should_respond_with :success
    end
    
    context 'Viewing the diff for a series of commits' do
      setup do
        @version.expects(:commits).with("ffcab".."bacff").returns([])
        get :show, :id => @version, :commit_shas => "ffcab..bacff"
      end
      should_respond_with :success
    end
    
    context 'Viewing the entire diff' do
      setup do
        @version.expects(:commits).returns([])
        get :show,  :id => @version
      end
      should_respond_with :success
    end
  end
end
