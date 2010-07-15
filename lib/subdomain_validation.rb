# encoding: utf-8
#--
#   Copyright (C) 2010 Marius Mårnes Mathiesen <marius@shortcut.no>
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

module SubdomainValidation
  def gitorious_host
    self["gitorious_host"]
  end
  
  def valid_subdomain?
    return gitorious_host =~ /[a-z0-9_]?\.[a-z0-9_]?/
  end

  def using_reserved_hostname?
    gitorious_host.split(".").first == Site::HTTP_CLONING_SUBDOMAIN
  end

  def valid_request_host?(host)
    return false if !valid_subdomain?
    subdomain_re = Regexp.new(".*\.?" + gitorious_host)
    return host =~ subdomain_re
  end
end
