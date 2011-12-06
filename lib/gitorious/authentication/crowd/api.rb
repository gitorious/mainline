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
require "net/http"

module Gitorious
  module Authentication
    class CrowdAPI
      attr_reader :application, :host, :port, :context

      def initialize(application, password, options = {})
        @application = application
        @application_password = password
        @host = options["host"] || "localhost"
        @port = options["port"] || 8095
        @context = options["context"] || ""
        key = "disable_ssl_verification"
        @disable_ssl_verification = options.key?(key) ? options[key] : false
      end

      def authenticate(username, password, &block)
        http_connection do |http|
          req_url = url("authentication", :username => username)
          payload = payload({ :password => password })
          response, body = http.request(build_request(req_url, payload))
          block.call(response.code, body)
        end
      end

      private
      def http_connection(&block)
        http = Net::HTTP.new(host, port)
        http.use_ssl = port == 443
        disable_verification = http.use_ssl? && disable_ssl_verification?
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if disable_verification
        http.start(&block)
      end

      def build_request(url, body)
        req = Net::HTTP::Post.new(url)
        req.body = body
        req.basic_auth(application, @application_password)
        req.add_field("Content-Type", "text/xml")
        req
      end

      def url(endpoint, params = {})
        req_params = params.map { |k,v| "#{k}=#{v}" }.join("&")
        "#{context}/rest/usermanagement/1/#{endpoint}?#{req_params}"
      end

      def payload(params)
        param_tags = params.map { |k,v| "<#{k}><value>#{v}</value></#{k}>" }.join("")
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>#{param_tags}"
      end

      def disable_ssl_verification?
        @disable_ssl_verification
      end
    end
  end
end
