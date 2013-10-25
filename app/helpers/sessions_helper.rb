# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

module SessionsHelper
  def login_menu(active)
    items = menu_items.map do |item|
      if active == item[0]
        "<li class=\"active\"><a>#{item[1]}</a></li>"
      else
        "<li>#{link_to(item[1], item[2])}</li>"
      end
    end

    "<ul class=\"nav nav-tabs gts-header-nav\">#{items.join}</ul>".html_safe
  end

  def menu_items
    return @menu_items if @menu_items
    @menu_items = []
    @menu_items << [:signup, "Sign up", new_user_path] if Gitorious.registrations_enabled?
    @menu_items << [:login, "Sign in", login_path]
    @menu_items << [:openid, "Sign in with OpenID", login_path(:method => :openid)] if Gitorious::OpenID.enabled?
    @menu_items << [:kerberos, "Sign in with Kerberos", { :controller => "sessions", :action => "http" }] if Gitorious::Kerberos.enabled?
    @menu_items << [:forgot_password, t("views.sessions.forgot"), forgot_password_users_path]
    @menu_items
  end

  def login_field_label
    Gitorious::Configuration.get("username_label", t("views.sessions.label"))
  end
end
