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

# Parses the line input to git's pre-receive and post-receive hooks:
# <old-value> SP <new-value> SP <ref-name> LF
# 
# The parser basically knows what action this line represents (create, update,
# delete) and whether its target is tag, a head or (custom for Gitorious) a
# merge request. The parser also knows the ref-name of the target.
#
# Example:
#
#     spec = PushSpecParser.new("9b0c1c59c682f9cb908a7aaf28a30b60846237fb",
#                               "8edf464ae27b6ff8d39600df05ebfbf6c1f1b0d3",
#                               "refs/heads/master")
#     spec.head? #=> true
#     spec.action_update? #=> true
#     spec.action_create? #=> false
#     spec.ref_name #=> "master"
#
# Refer to unit tests for further examples.
#
class PushSpecParser
  attr_reader :from_sha, :to_sha, :ref

  def initialize(from_sha, to_sha, ref)
    @from_sha = Sha.new(from_sha)
    @to_sha = Sha.new(to_sha)
    @ref = Ref.new(ref)
  end

  def to_s
    "<Spec from: #{@from_sha.sha} to: #{@to_sha.sha} for: #{ref_name}>"
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

  # Internal representation of a single sha.
  class Sha
    def initialize(sha)
      @sha = sha
    end

    def null_sha?
      (@sha =~ /^0+$/) == 0
    end

    def sha
      @sha
    end
  end

  # Internal representation of a Git ref, e.g. res/tags/topic-branch
  class Ref
    attr_reader :name

    def initialize(ref)
      r, @type, @name = ref.split("/", 3)
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
