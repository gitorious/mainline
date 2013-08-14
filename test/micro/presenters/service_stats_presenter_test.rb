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

require 'fast_test_helper'
require 'presenters/service_stats_presenter'

class ServiceStatsPresenterTest < Minitest::Spec
  it "delegates user to service" do
    service = Service.new(:user => :joe)
    presenter = ServiceStatsPresenter.new(service)

    assert_equal :joe, presenter.user
  end

  it "delegates to_param to service" do
    service = Service.new(:to_param => 123)
    presenter = ServiceStatsPresenter.new(service)

    assert_equal 123, presenter.to_param
  end

  it "formats the number of runs" do
    service = Service.new(:successful_request_count => 3, :failed_request_count => 5)
    presenter = ServiceStatsPresenter.new(service)

    assert_equal '<span class="gts-pos">3</span>/<span class="gts-neg">5</span>', presenter.runs
  end

  describe "#last_response" do
    def last_response(value)
      service = Service.new(:last_response => value)
      ServiceStatsPresenter.new(service).last_response
    end

    it "formats the response as a success for statuses between 200 and 299" do
      assert_equal '<strong class="gts-pos">200 OK</strong>', last_response('200 OK')
      assert_equal '<strong class="gts-pos">201 Created</strong>', last_response('201 Created')
      assert_equal '<strong class="gts-pos">299 Foo</strong>', last_response('299 Foo')
    end

    it "formats the response as an error for statuses between 400 and 599" do
      assert_equal '<strong class="gts-neg">400 Fail</strong>', last_response('400 Fail')
      assert_equal '<strong class="gts-neg">404 Not Found</strong>', last_response('404 Not Found')
      assert_equal '<strong class="gts-neg">500 Server error</strong>', last_response('500 Server error')
      assert_equal '<strong class="gts-neg">599 Baz</strong>', last_response('599 Baz')
    end

    it "does not style the response for other statuses" do
      assert_equal '199 Bar', last_response('199 Bar')
      assert_equal '300 Moved', last_response('300 Moved')
      assert_equal '399 Foo', last_response('399 Foo')
      assert_equal '600', last_response('600')
    end
  end

  it "delegates everything else to adapter" do
    adapter = stub(:foo => 1, :bar => 2, :baz => 3)
    service = Service.new(:adapter => adapter)
    presenter = ServiceStatsPresenter.new(service)

    assert_equal 1, presenter.foo
    assert_equal 2, presenter.bar
    assert_equal 3, presenter.baz
  end
end
