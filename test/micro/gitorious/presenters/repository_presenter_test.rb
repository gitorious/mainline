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
require "fast_test_helper"
require "presenters/repository_presenter"

class RepositoryPresenterTest < MiniTest::Spec
  before do
    @repo = Repository.new({
      :id => 42,
      :name => "mainline",
      :to_param => "gitorious/mainline",
      :open_merge_requests => [{}, {}],
      :gitdir => "some/path",
      :project => Project.new(:slug => "gitorious")
    })
  end

  describe "#id" do
    it "returns underlying model id" do
      assert_equal 42, RepositoryPresenter.new(@repo).id
    end
  end

  describe "#name" do
    it "returns underlying model name" do
      assert_equal "mainline", RepositoryPresenter.new(@repo).name
    end
  end

  describe "#gitdir" do
    it "returns underlying model gitdir" do
      assert_equal "some/path", RepositoryPresenter.new(@repo).gitdir
    end
  end

  describe "#to_param" do
    it "returns underlying model to_param" do
      assert_equal "gitorious/mainline", RepositoryPresenter.new(@repo).to_param
    end
  end

  describe "#open_merge_request_count" do
    it "returns underlying count of merge requests" do
      assert_equal 2, RepositoryPresenter.new(@repo).open_merge_request_count
    end
  end

  describe "#slug" do
    it "returns project/repository slug" do
      assert_equal "gitorious/mainline", RepositoryPresenter.new(@repo).slug
    end
  end

  describe "#project" do
    it "returns project presenter" do
      assert_equal ProjectPresenter, RepositoryPresenter.new(@repo).project.class
    end
  end

  describe "#internal?" do
    it "returns underlying model internal?" do
      internal = mock('internal')
      @repo.stubs(:internal?).returns(internal)
      assert_equal internal, RepositoryPresenter.new(@repo).internal?
    end
  end
end
