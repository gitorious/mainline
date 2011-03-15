# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 August Lilleaas <augustlilleaas@gmail.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2009 Bill Marquette <bill.marquette@gmail.com>
#   Copyright (C) 2010 Christian Johansen <christian@shortcut.no>

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

# These helpers are used both in views and some controllers
#
module RoutingHelper
  # turns ["foo", "bar"] route globbing parameters into "foo/bar"
  # Note that while the path components will be uri unescaped, any
  # '+' will be preserved
  def desplat_path(*paths)
    # we temporarily swap the + out with a magic byte, so
    # filenames/branches with +'s won't get unescaped to a space
    paths.flatten.compact.map do |p|
      CGI.unescape(p.gsub("+", "\001")).gsub("\001", '+')
    end.join("/")
  end

  # turns "foo/bar" into ["foo", "bar"] for route globbing
  def ensplat_path(path)
    path.split("/").select{|p| !p.blank? }
  end

  # return the url with the +repo+.owner prefixed if it's a mainline repo,
  # otherwise return the +path_spec+
  # if +path_spec+ is an array (and no +args+ given) it'll use that as the 
  # polymorphic-url-style (eg [@project, @repo, @foo])
  def repo_owner_path(repo, path_spec, *args)
    if repo.team_repo?
      if path_spec.is_a?(Symbol)
        return send("group_#{path_spec}", *args.unshift(repo.owner))
      else
        return *unshifted_polymorphic_path(repo, path_spec)
      end
    elsif repo.user_repo?
      if path_spec.is_a?(Symbol)
        return send("user_#{path_spec}", *args.unshift(repo.owner))
      else
        return *unshifted_polymorphic_path(repo, path_spec)
      end
    else
      if path_spec.is_a?(Symbol)
        return send(path_spec, *args)
      else
        return *path_spec
      end
    end
  end
end
