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
require "gitorious"

module Gitorious
  module View
    DEFAULT_FOOTER_LINKS = [["Professional Gitorious Services", "http://gitorious.com/"]]

    def self.additional_footer_links
      Gitorious::Configuration.get("additional_footer_links", DEFAULT_FOOTER_LINKS)
    end

    def self.terms_of_service_url
      Gitorious::Configuration.get("terms_of_service_url", "http://en.gitorious.org/tos")
    end

    def self.privacy_policy_url
      Gitorious::Configuration.get("privacy_policy_url", "http://en.gitorious.org/privacy_policy")
    end

    def self.discussion_url
      Gitorious::Configuration.get("discussion_url", "http://groups.google.com/group/gitorious")
    end

    def self.blog_url
      Gitorious::Configuration.get("discussion_url", "http://blog.gitorious.org")
    end
  end
end
