# encoding: utf-8
#--
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

  # determines which form to display for login
  def login_method
    if params[:method]=='openid'
      "<script  type=\"text/javascript\">
         $(document).ready(function(){
           $(\"#regular_login_fields\").toggle();
           $(\"#openid_login_fields\").toggle();
         })
      </script>"
    end
  end

  def switch_login(title, action)
    link_to_function(title, <<-EOS)

      $(".foo1").click(
      function() {
        $("body").css("background", "red");
        $("#regular_login_fields").addClass("login_hidden");
        $("#openid_login_fields").removeClass("login_hidden");
      });

EOS
  end

  def switch_op_login(title, action)
    link_to_function(title, <<-EOS)
      $(".regular-switch a").click(
      function() {
        $("p.regular-switch").toggle();
        $("#openid_login_fields").addClass("login_hidden");
        $("#regular_login_fields").removeClass("login_hidden");
      });
    EOS
  end
end
