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

require "project_presenter"

class ProjectPresenterTest < Minitest::Spec
  before do
    @project = ProjectPresenter.new(Project.new(
          :id => 13,
          :title => "Gitorious",
          :slug => "gitorious",
          :wiki_enabled => false,
          :description => "Hmm, yeah"))
  end

  it "exposes title as name" do
    assert_equal "Gitorious", @project.name
  end

  it "exposes slug" do
    assert_equal "gitorious", @project.slug
  end

  it "converts to param" do
    assert_equal "gitorious", @project.to_param
  end

  it "exposes description" do
    assert_equal "Hmm, yeah", @project.description
  end

  it "exposes wiki enabled" do
    refute @project.wiki_enabled?
  end

  it "identifies as a Project" do
    assert @project.is_a?(Project)
  end
end
