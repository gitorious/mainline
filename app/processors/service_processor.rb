# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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
require "http_client"
class ServiceProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousPostReceiveWebHook"
  attr_accessor :repository, :user, :http_client

  def initialize(http_client = HttpClient.new(logger))
    @http_client = http_client
  end

  def on_message(message)
    begin
      self.user = User.find_by_login!(message["user"])
      self.repository = Repository.find(message["repository_id"])
      notify_services(message["payload"], services(message["service_id"]))
    rescue ActiveRecord::RecordNotFound => e
      logger.error(e.message)
    end
  end

  def notify_services(payload, services = default_services)
    services.each do |service|
      begin
        Timeout.timeout(10) do
          result = service.adapter.notify(http_client, payload)
          if successful_response?(result)
            service.successful_connection("#{result.code} #{result.message}")
          else
            service.failed_connection("#{result.code} #{result.message}")
            logger.error("Service failed:\n#{result.body}")
          end
        end
      rescue Errno::ECONNREFUSED
        service.failed_connection("Connection refused")
      rescue Timeout::Error
        service.failed_connection("Connection timed out")
      rescue SocketError
        service.failed_connection("Socket error")
      end
    end
  end

  def successful_response?(response)
    case response
    when Net::HTTPSuccess, Net::HTTPMovedPermanently, Net::HTTPTemporaryRedirect, Net::HTTPFound
      return true
    else
      return false
    end
  end

  private

  def default_services
    [Service.global_services, repository.services].flatten
  end

  def services(service_id)
    return [repository.services.find(service_id)] if service_id
    default_services
  end

end
