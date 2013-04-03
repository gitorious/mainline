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

class WikiRepositoryTest < ActiveSupport::TestCase
  should "create repository from project data" do
    project = Project.create!({
        :title => "Entombed",
        :slug => "entombed",
        :description => "A musical project from Sweden",
        :user => users(:moe),
        :owner => users(:moe)
      })

    WikiRepository.create!(project)

    wiki = project.wiki_repository
    assert_instance_of Repository, wiki
    assert_equal "entombed#{WikiRepository::NAME_SUFFIX}", wiki.name
    assert_equal Repository::KIND_WIKI, wiki.kind
    refute project.repositories.include?(wiki)
    assert project.cloneable_repositories.include?(wiki)
    assert_equal project.owner, wiki.owner
  end
end
