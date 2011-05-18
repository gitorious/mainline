# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

# This is required because ActiveMessaging actually forcefully loads
# all processors before initializers are run. Hopefully this can go away
# when the vendored ActiveMessaging plugin is removed.
require File.join(Rails.root, "config/initializers/messaging")

class WebHookProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousPostReceiveWebHook"
  attr_accessor :repository, :user

  def on_message(message)
    begin
      self.user = User.find_by_login!(message["user"])
      self.repository = Repository.find(message["repository_id"])
      notify_web_hooks(message["payload"])
    rescue ActiveRecord::RecordNotFound => e
      logger.error(e.message)
    end
  end

  def notify_web_hooks(payload)
    repository.hooks.each do |hook|
      begin
        Timeout.timeout(10) do
          result = post_payload(hook, payload)
          if successful_response?(result)
            hook.successful_connection("#{result.code} #{result.message}")
          else
            hook.failed_connection("#{result.code} #{result.message}")
          end
        end
      rescue Errno::ECONNREFUSED
        hook.failed_connection("Connection refused")
      rescue Timeout::Error
        hook.failed_connection("Connection timed out")
      rescue SocketError
        hook.failed_connection("Socket error")
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

  def post_payload(hook, payload)
    Net::HTTP.post_form(URI.parse(hook.url), {"payload" => payload.to_json})
  end
end
