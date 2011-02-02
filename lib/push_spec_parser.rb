# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

class PushSpecParser
  attr_reader :from_sha, :to_sha, :ref

  def initialize(from_sha, to_sha, ref)
    @from_sha = Sha.new(from_sha)
    @to_sha = Sha.new(to_sha)
    @ref = Ref.new(ref)
  end

  def tag?
    ref.tag?
  end

  def head?
    ref.head?
  end

  def merge_request?
    ref.merge_request?
  end

  def action_create?
    from_sha.null_sha?
  end

  def action_update?
    !from_sha.null_sha? && !to_sha.null_sha?
  end

  def action_delete?
    to_sha.null_sha?
  end

  def ref_name
    ref.name
  end

  class Sha
    def initialize(sha)
      @sha = sha
    end

    def null_sha?
      @sha == "0" * 32
    end
  end

  class Ref
    attr_reader :name

    def initialize(ref)
      r, @type, @name = ref.split("/")
    end

    def tag?
      @type == "tags"
    end

    def head?
      @type == "heads"
    end

    def merge_request?
      @type == "merge-requests"
    end
  end
end
