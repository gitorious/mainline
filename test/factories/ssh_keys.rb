# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

FactoryGirl.define do
  sequence(:key) do |n|
    "ssh-rsa #{["asdsad#{n}"].pack("m")} foo#{n}@bar"
  end

  factory(:ssh_key) do |k|
    k.user {|u| u.association(:user) }
    k.key { Factory.next(:key) }
    k.ready true
  end
end
