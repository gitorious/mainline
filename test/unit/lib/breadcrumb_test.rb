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

class BreadcrumbTest < ActiveSupport::TestCase

  context "Breadcrumb::Folder" do
    setup do
      @head = Object.new
      def @head.name
        return "head"
      end
      @folder = Breadcrumb::Folder.new(:paths => %w(foo bar baz), :head => @head, :repository => nil)
    end

    should " return a relevant title" do
      assert_equal 'baz', @folder.title
    end

    should " return parents all the way up to a Branch" do
      branch = @folder.breadcrumb_parent.breadcrumb_parent.breadcrumb_parent.breadcrumb_parent
      assert_instance_of Breadcrumb::Branch, branch
    end

    should "have a top level folder" do
      folder = Breadcrumb::Folder.new(:paths => [], :head => @head, :repository => nil)
      assert_equal '/', folder.title
    end
  end

  context "Breadcrumb::Branch" do
    setup do
      @o = Object.new
      def @o.name
        return "Yikes"
      end
      @branch = Breadcrumb::Branch.new(@o, 'I am a parent')
    end

   should " return its title" do
      assert_equal 'Yikes', @branch.title
    end

   should " return its parent" do
      assert_equal "I am a parent", @branch.breadcrumb_parent
    end
  end

  context "Breadcrumb::Blob" do
    setup do
      @blob = Breadcrumb::Blob.new(:paths => %w(foo), :name => 'README', :head => nil ,:repository => nil)
    end

   should " have a Folder as its parent" do
      assert_instance_of Breadcrumb::Folder, @blob.breadcrumb_parent
    end

   should " keep its path" do
      assert_equal %w(foo), @blob.path
    end
  end

  context "Breadcrumb::Commit" do
    setup do
      @repo = mock
      @commit = Breadcrumb::Commit.new(:repository => @repo, :id => 'ffc0349')
    end

   should " return its title" do
      assert_equal 'ffc0349', @commit.title
    end

   should " return the Repository as its parent" do
      assert_equal @repo, @commit.breadcrumb_parent
    end
  end

  context "Breadcrumb::Page" do
    setup do
      project = mock
      page = mock
      page.stubs(:title).returns('Home')
      @page = Breadcrumb::Page.new(page, project)
    end

   should " return a Wiki as its parent" do
      assert_instance_of Breadcrumb::Wiki, @page.breadcrumb_parent
    end

   should " return its title" do
      assert_equal 'Home', @page.title
    end
  end

  context "Breadcrumb::Memberships" do
    setup do
      @group = mock("Group")
      @crumb = Breadcrumb::Memberships.new(@group)
    end

   should " return a Froup as its parent" do
      assert_equal @group, @crumb.breadcrumb_parent
    end

   should " return its title" do
      assert_equal 'Members', @crumb.title
    end
  end

  context "Breadcrumb::Committerships" do
    setup do
      @repo = mock("Repostitory")
      @crumb = Breadcrumb::Committerships.new(@repo)
    end

   should "return a Froup as its parent" do
      assert_equal @repo, @crumb.breadcrumb_parent
    end

   should "return its title" do
      assert_equal 'Collaborators', @crumb.title
    end
  end
end
