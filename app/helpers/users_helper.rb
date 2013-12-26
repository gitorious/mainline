# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tor.arne.vestbo@trolltech.com>
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

module UsersHelper
  include FavoritesHelper
  def encoded_mail_to(email)
    mail_to(email, nil, :replace_at => "AT@NOSPAM@",
      :replace_dot => "DOT", :encode => "javascript")
  end

  def encoded_mail(email)
    email = email.gsub(/@/,"AT@NOSPAM@")
    email.gsub(/\./,"DOT")
  end

  def mangled_mail(email)
    if Gitorious::Configuration.get("mangle_email_addresses", true)
      user, domain = h(email).split("@", 2)
      return user if domain.blank?
      domain, ext = domain.split(".", 2)
      str = "#{user.to_s} @#{domain[0, domain.length/2].to_s}"
      "#{str}&hellip;#{domain[-(domain.length/3)..-1]}.#{ext}".html_safe
    else
      h(email)
    end
  end

  def render_email(email)
    ("&lt;" + mangled_mail(email).to_s + "&gt;").html_safe
  end

  def is_current_user?(a_user)
    logged_in? && current_user == a_user
  end

  def show_merge_request_count_for_user?(a_user)
    is_current_user?(a_user) &&
         !a_user.review_repositories_with_open_merge_request_count.blank?
  end

  def personified(user, current_user_msg, other_user_msg)
    is_current_user?(user) ? h(current_user_msg) : h(other_user_msg)
  end

  def favorites_heading_for(user)
    personified(user, "You are watching", "#{user.title} is watching")
  end

  def no_watchings_notice_for(user)
    msg = personified(user, "You are not", "#{user.title} is not") +
      " watching anything yet."
    if is_current_user?(user)
      msg << " Click the watch icon to get events fed into this page."
    end
    msg
  end

  def showing_newsfeed?
    is_current_user?(@user) && params[:events] != "outgoing"
  end

  def newsfeed_or_user_events_link
    if showing_newsfeed?
      link_to "Show my activities", user_path(@user, {:events => "outgoing"})
    else
      link_to "Show my news feed", user_path(@user)
    end
  end
end
