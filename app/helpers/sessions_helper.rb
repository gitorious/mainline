#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Patrick Aljord <patcito@gmail.com>
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

  # determines which form to display for login
  def login_method
    if params[:method]=='openid'
      "<script  type=\"text/javascript\"> Event.observe(window, 'load',
      function() {
Element.toggle(\"regular_login_fields\");
Element.toggle(\"openid_login_fields\");
})
    </script>"
    end
  end

  def switch_login(title, action)
    link_to_function title do |page|
      page.toggle "regular_login_fields"
      page.toggle "openid_login_fields"
    end
  end
end
