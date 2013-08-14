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
require 'presenters/service_type_presenter'
require 'presenters/service_stats_presenter'

class ServiceTypePresenterTest < Minitest::Spec
  class FakeServiceType
    def self.service_type
      "foo"
    end

    def self.label
      "type label"
    end
  end

  class SecondFakeService
  end

  describe ".for_repository" do
    it "returns a presenter for every type" do
      Service.stubs(:types => [FakeServiceType, SecondFakeService])
      repository =  Repository.new(:services => [:the_services])

      presenters = ServiceTypePresenter.for_repository(repository, :the_invalid_service)

      assert_equal [FakeServiceType, SecondFakeService], presenters.map(&:type)
      assert_equal [:the_invalid_service, :the_invalid_service], presenters.map(&:invalid_service)
    end
  end

  it "returns template path" do
    presenter = ServiceTypePresenter.new(FakeServiceType, [], Repository.new)
    assert_equal "/services/foo", presenter.template_path
  end

  it "returns service type" do
    presenter = ServiceTypePresenter.new(FakeServiceType, [], Repository.new)
    assert_equal "foo", presenter.service_type
  end

  it "returns service type" do
    presenter = ServiceTypePresenter.new(FakeServiceType, [], Repository.new)
    assert_equal "type label", presenter.label
  end

  it 'returns services of given type wrapped in a StatsPresenter' do
    same_type = Service.new(:service_type => "foo")
    other_type = Service.new(:service_type => "bar")
    services = [same_type, other_type]
    presenter = ServiceTypePresenter.new(FakeServiceType, services, Repository.new)

    assert_equal [same_type], presenter.services.map(&:service)
    assert presenter.services.first.is_a?(ServiceStatsPresenter)
  end

  describe "#adapter" do
    let(:new_service) { Service.new(:adapter => :new_service_adapter) }
    let(:repository) { Repository.new }

    before do
      Service.stubs(:for_type_and_repository).with(FakeServiceType.service_type, repository).returns(new_service)
    end

    it "returns invalid_service when it is of given type" do
      invalid_service = Service.new(:service_type => FakeServiceType.service_type,
                             :adapter => :service_adapter)
      presenter = ServiceTypePresenter.new(FakeServiceType, [], repository, invalid_service)

      assert_equal :service_adapter, presenter.adapter
    end

    it "does not return invalid service when it is of different type" do
      invalid_service = Service.new(:service_type => 'bar',
                             :adapter => :service_adapter)
      presenter = ServiceTypePresenter.new(FakeServiceType, [], repository, invalid_service)

      assert_equal :new_service_adapter, presenter.adapter
    end

    it "returns a new service" do
      presenter = ServiceTypePresenter.new(FakeServiceType, [], repository)

      assert_equal :new_service_adapter, presenter.adapter
    end
  end
end
