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


require File.dirname(__FILE__) + '/../../test_helper'

class MergeRequestGitBackendProcessorTest < ActiveSupport::TestCase
  
  def setup
    @processor = MergeRequestGitBackendProcessor.new
    @merge_request = merge_requests(:moes_to_johans)
    @repository = @merge_request.target_repository
  end
  
  def teardown
    @processor = nil
  end

  context "Deleting the merge request and its tracking branch" do
    setup do
      @msg = {:merge_request_id => @merge_request.to_param, :action => "delete"}
      @processor.instance_variable_set("@merge_request", @merge_request)
    end
    
    should "delete the tracking repo and the merge request itself" do
      @merge_request.expects(:delete_target_repository_ref).once
      @merge_request.expects(:destroy).once
      @processor.on_message(@msg.to_json)
    end

    should "handle non-existing target gits" do
      @merge_request.expects(:destroy).once
      assert_nothing_raised do
        @processor.on_message(@msg.to_json)
      end
    end
  end

  context "Parsing the action" do
    should "understand the delete command" do
      msg = {:merge_request_id => @merge_request.to_param, :action => "delete"}
      @processor.expects(:do_delete).once
      @processor.on_message(msg.to_json)
      assert_equal :delete, @processor.action
      assert_equal @merge_request, @processor.merge_request
    end
    
    should "understand the close command" do
      msg = {:merge_request_id => @merge_request.to_param, :action => "close"}
      @processor.expects(:do_close)
      @processor.on_message(msg.to_json)
    end
    
    should "understand the reopen command" do
      msg = {:merge_request_id => @merge_request.to_param, :action => "reopen"}
      @processor.expects(:do_reopen)
      @processor.on_message(msg.to_json)
    end
  end
end
