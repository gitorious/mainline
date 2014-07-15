# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

class FakeGritCommit
  attr_reader :id, :parent_ids
  def initialize(oid)
    @id = oid
    @parent_ids = ["a" * 40]
  end
end

class FakeRuggedHead
  attr_reader :target, :name
  def initialize(target, name)
    @target = target
    @name = name
  end
end

class FakeRuggedCommit
  attr_reader :oid, :parent_ids
  def initialize(oid)
    @oid = oid
    @parent_ids = ["a" * 40]
  end
end

class FakeRuggedRepository
  def head
    FakeRuggedHead.new(FakeRuggedCommit.new("b" * 40), "refs/heads/master")
  end

  def lookup(id)
    FakeRuggedCommit.new(id)
  end
end
