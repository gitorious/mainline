# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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
require "gitorious/view"

class UnexpectedSiteContext < Exception;
  attr_reader :target
  def initialize(target); @target = target; end
end

module Gitorious
  module View
    module SiteHelper
      def current_site
        @current_site || Site.default
      end

      def find_current_site(project = nil)
        project ||= current_project
        @current_site ||= begin
                            if project
                              project.site
                            else
                              if !subdomain_without_common.blank?
                                Site.find_by_subdomain(subdomain_without_common)
                              end
                            end
                          end
      end

      def subdomain_without_common
        tld_length = Gitorious.host.split(".").length - 1
        ActionDispatch::Http::URL.extract_subdomains(request.host, tld_length).select do |s|
          s !~ /^(ww.|secure)$/
        end.first
      end

      # TODO: Project argument is optional now to support the old
      # redirect_to_current_site method. Remove when all uses of the
      # filter has been converted
      def verify_site_context!(project = nil)
        return true if !request.get?
        site = find_current_site(project)
        return true if site.nil?

        if !site.subdomain.blank?
          if subdomain_without_common != site.subdomain
            host = "#{site.subdomain}.#{Gitorious.host}"
            host << ":#{request.port}" if ![80, 443].include?(request.port)
            raise UnexpectedSiteContext.new("#{request.env['rack.url_scheme']}://#{host}#{request.path}")
          end
        elsif !subdomain_without_common.blank?
          host = Gitorious.host
          host << ":#{request.port}" if ![80, 443].include?(request.port)
          raise UnexpectedSiteContext.new("#{request.env['rack.url_scheme']}://#{host}#{request.path}")
        end
      end
    end
  end
end
