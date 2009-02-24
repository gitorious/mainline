#--
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
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
  def encoded_mail_to(email)
    mail_to(email, nil, :replace_at => "AT@NOSPAM@", 
      :replace_dot => "DOT", :encode => "javascript")
  end

  def encoded_mail(email)
    email = email.gsub(/@/,"AT@NOSPAM@")
    email.gsub(/\./,"DOT")
  end
  
  def mangled_mail(email)
    user, domain = h(email).split("@", 2)
    domain, ext = domain.split(".", 2)
    user + " @" + domain[0, domain.length/2] + 
      "&hellip;" + domain[-(domain.length/3)..-1] + ".#{ext}"
  end
end
