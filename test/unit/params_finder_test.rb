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

class DummyAuthorizer
  def initialize(allow = true)
    @allow = allow
  end

  def authorize_access_to(thing)
    raise "Disallowed!" if !@allow
    thing
  end
end

class ParamsFinderTest < ActiveSupport::TestCase
  def setup
    @project = Project.new(:title => "My project")
    @repository = Repository.new(:name => "My repo")
    @predefs = { :project => @project, :repository => @repository }
  end

  should "expose pre-defined project and repository" do
    finder = ParamsFinder.new(nil, {}, @predefs)

    assert_equal @project, finder.project
    assert_equal @repository, finder.repository
  end

  should "find merge request from merge_request_id param" do
    repo = repositories(:johans)
    mr = repo.merge_requests.public.first
    params = { :merge_request_id => mr.sequence_number }
    finder = ParamsFinder.new(DummyAuthorizer.new, params, { :repository => repo })

    assert_equal mr, finder.merge_request
  end

  should "raise on disallowed merge request" do
    repo = repositories(:johans)
    mr = repo.merge_requests.public.first
    params = { :merge_request_id => mr.sequence_number }
    finder = ParamsFinder.new(DummyAuthorizer.new(false), params, { :repository => repo })

    assert_raises(RuntimeError) do
      finder.merge_request
    end
  end

  context "merge request versions" do
    setup do
      @repo = repositories(:johans)
      @mr = @repo.merge_requests.public.first
      @first = @mr.create_new_version('ffcca0')
      @second = @mr.create_new_version('ffcca0')
    end

    should "find last merge request version by default" do
      params = { :merge_request_id => @mr.sequence_number }
      finder = ParamsFinder.new(DummyAuthorizer.new, params, { :repository => @repo })

      assert_equal @second, finder.merge_request_version
    end

    should "raise on disallowed merge request version" do
      params = { :merge_request_id => @mr.sequence_number }
      finder = ParamsFinder.new(DummyAuthorizer.new(false), params, { :repository => @repo })

      assert_raises(RuntimeError) do
        finder.merge_request_version
      end
    end

    should "find specified merge request version" do
      params = { :merge_request_id => @mr.sequence_number, :version => 1 }
      finder = ParamsFinder.new(DummyAuthorizer.new, params, { :repository => @repo })

      assert_equal @first, finder.merge_request_version
    end
  end
end
