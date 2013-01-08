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
require "presenters/project_presenter"

class ProjectPresenterTest < MiniTest::Spec
  before do
    @project = Project.new({
      :id => 13,
      :title => "Gitorious",
      :slug => "gitorious",
      :description => "Hmm, yeah",
      :to_param => "gitorious"
    })
  end

  describe "#title" do
    it "returns underlying model title" do
      assert_equal "Gitorious", ProjectPresenter.new(@project).title
    end
  end

  describe "#slug" do
    it "returns underlying model slug" do
      assert_equal "gitorious", ProjectPresenter.new(@project).slug
    end
  end

  describe "#description" do
    it "returns underlying model description" do
      assert_equal "Hmm, yeah", ProjectPresenter.new(@project).description
    end
  end

  describe "#to_param" do
    it "returns underlying model to_param" do
      assert_equal "gitorious", ProjectPresenter.new(@project).to_param
    end
  end
end
