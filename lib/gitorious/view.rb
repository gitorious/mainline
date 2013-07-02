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

    def self.footer_links(app)
      @footer_links ||= {}
      sd = app.current_site.subdomain
      return @footer_links[sd] if @footer_links[sd] && Rails.env.production?
      @footer_links[sd] = Gitorious::Configuration.group_get(["sites", app.current_site.subdomain], "footer_links") do
        [["About Gitorious", app.about_path],
          ["Discussion group", "http://groups.google.com/group/gitorious"],
          ["Blog", "http://blog.gitorious.org"],
          ["Terms of Service", "http://en.gitorious.org/tos"],
          ["Privacy Policy", "http://en.gitorious.org/privacy_policy"]]
      end + Gitorious::Configuration.get("additional_footer_links", [])
    end

    def self.javascripts
      @javascripts ||= []
    end

    def self.stylesheets
      @stylesheets ||= []
    end

    def self.theme_javascripts(site)
      @themejs ||= {}
      return @themejs[site.subdomain] if @themejs[site.subdomain] && Rails.env.production?
      @themejs[site.subdomain] = javascripts
      theme = Gitorious::Configuration.group_get(["sites", site.subdomain], "theme_js")
      @themejs[site.subdomain] = @themejs[site.subdomain] + [theme] if theme
      @themejs[site.subdomain]
    end

    def self.theme_stylesheets(site)
      @themecss ||= {}
      return @themecss[site.subdomain] if @themecss[site.subdomain] && Rails.env.production?
      @themecss[site.subdomain] = stylesheets
      theme = Gitorious::Configuration.group_get(["sites", site.subdomain], "theme_css")
      @themecss[site.subdomain] = @themecss[site.subdomain] + [theme] if theme
      @themecss[site.subdomain]
    end
  end
end
