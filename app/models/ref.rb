# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

class Ref
  MERGE_REQUEST_REGEXP = %r{^refs/merge-requests/(\d+)$}
  NULL_SHA = "0000000000000000000000000000000000000000"

  attr_accessor :repository, :name

  def self.action(oldsha, newsha, merge_base)
    if null_sha?(oldsha)
      :create
    elsif null_sha?(newsha)
      :delete
    else
      merge_base != oldsha ? :force_update : :update
    end
  end

  def self.null_sha?(sha)
    sha == NULL_SHA
  end

  def initialize(repository, name)
    @repository = repository
    @name = name
  end

  def merge_request
    seqnum = name[MERGE_REQUEST_REGEXP, 1]
    repository.merge_requests.find_or_initialize_by_sequence_number(seqnum) if seqnum
  end

  def force_update_allowed?
    !repository.deny_force_pushing
  end

end
