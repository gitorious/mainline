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
  sequence(:email) do |n|
    "john#{n}@example.com"
  end

  sequence(:login) do |n|
    "user#{n}"
  end

  factory(:user) do |u|
    u.login { Factory.next(:login) }
    u.email { Factory.next(:email) }
    u.terms_of_use "1"
    u.salt "7e3041ebc2fc05a40c60028e2c4901a81035d3cd"
    u.crypted_password "00742970dc9e6319f8019fd54864d3ea740f04b1" # test
    u.created_at Time.now.to_s(:db)
    u.aasm_state "terms_accepted"
    u.is_admin false
    u.activated_at Time.now.to_s(:db)
  end
end
