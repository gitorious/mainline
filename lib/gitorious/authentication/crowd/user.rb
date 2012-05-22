# encoding: utf-8
#--
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
require "nokogiri"

module Gitorious
  module Authentication
    class CrowdUser
      attr_reader :username, :display_name, :email

      def initialize(username, display_name, email)
        @username = username
        @display_name = display_name
        @email = email
      end

      def self.from_xml_string(xml)
        doc = Nokogiri::XML(xml)
        new(CrowdUser.map_username(doc.css("user").attr("name").to_s),
            doc.css("display-name").text,
            doc.css("email").text)
      end

      def self.map_username(username)
        username.gsub(".", "-")
      end

      def to_user
        user = User.new
        user.login = username
        user.fullname = display_name
        user.email = email
        user.password = "left_blank"
        user.password_confirmation = "left_blank"
        user.terms_of_use = "1"
        user.aasm_state = "terms_accepted"
        user.activated_at = Time.now.utc
        user.save!
        # Reset the password to something random
        user.reset_password!
        user
      end
    end
  end
end
