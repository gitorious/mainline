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
require "gitorious/messaging"
require "gitorious/authorization"

# This module is provided mainly for use with use cases that require
# a message publisher and/or authorizor injected, e.g.:
#
#     cmd = PrepareRepositoryClone.new(Gitorious::App, repo, user)

module Gitorious
  module App
    extend Gitorious::Messaging::Publisher
    extend Gitorious::Authorization
  end
end
