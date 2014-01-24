# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class CommittershipPresenterTest < ActiveSupport::TestCase
  setup do
    @view_context = stub
    @committer = Group.new
    @committership = Committership.new(committer: @committer)

    @presenter = CommittershipPresenter.new(@committership, @view_context)
  end

  context  "#label" do
    should "returns label" do
      @committer.name = "The foos"
      @view_context.stubs(:link_to).with("The foos", @committer).returns("/foo")
      assert_equal "/foo (Team)", @presenter.label
    end

    should "returns label for super group" do
      @view_context.stubs(:link_to).with("Super Group*", "/about/faq").returns("/about")
      @committership.stubs(id: "super")

      assert_equal "/about (Team)", @presenter.label
    end
  end

  should "formats the permissions" do
    @committership.build_permissions(:review, :commit)

    assert_equal  "review, commit", @presenter.permissions
  end

  context "#creator" do
    should "returns link to creator profile if available" do
      creator = User.new(login: "Bob")
      @committership.creator = creator
      @view_context.stubs(:link_to).with("bob", creator).returns("/~bob")

      assert_equal "/~bob", @presenter.creator
    end

    should "otherwise returns nil" do
      refute @presenter.creator
    end
  end

  should "format the created_at date" do
    @committership.created_at = DateTime.parse("2011-01-02 15:00")

    assert_equal "02 Jan 15:00", @presenter.created_at
  end

  context "#actions" do
    include ViewContextHelper

    should "returns super group message and delete link" do
      repository = repositories(:johans)
      committership = SuperGroup.super_committership(repository.committerships)
      presenter = CommittershipPresenter.new(committership, view_context)

      assert_include presenter.actions, 'method="delete"'
      refute presenter.actions.include?('/edit')
    end

    should "returns edit and delete buttons otherwise" do
      committership = committerships(:johan_johans)
      presenter = CommittershipPresenter.new(committership, view_context)

      assert_include presenter.actions, '/edit'
      assert_include presenter.actions, 'method="delete"'
      assert_include presenter.actions, 'last committer with admin rights'
    end
  end
end
