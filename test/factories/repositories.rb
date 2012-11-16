# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

FactoryGirl.define do
  sequence(:repository_name) do |n|
    "repo_#{n}"
  end

  factory(:repository) do |r|
    r.name { Factory.next(:repository_name) }
    r.kind Repository::KIND_PROJECT_REPO
  end

  factory(:merge_request_repository, :parent => :repository) do |r|
    r.kind Repository::KIND_TRACKING_REPO
  end
end
