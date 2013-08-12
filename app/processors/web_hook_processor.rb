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

class WebHookProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousPostReceiveWebHook"
  attr_accessor :repository, :user

  def on_message(message)
    begin
      self.user = User.find_by_login!(message["user"])
      self.repository = Repository.find(message["repository_id"])
      notify_web_hooks(message["payload"], hooks(message["web_hook"]))
    rescue ActiveRecord::RecordNotFound => e
      logger.error(e.message)
    end
  end

  def notify_web_hooks(payload, hooks = default_hooks)
    hooks.each do |hook|
      begin
        Timeout.timeout(10) do
          result = post_payload(hook, payload)
          if successful_response?(result)
            hook.successful_connection("#{result.code} #{result.message}")
          else
            hook.failed_connection("#{result.code} #{result.message}")
            logger.error("Webhook failed:\n#{result.body}")
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

  require "net/https"

  def post_payload(hook, payload)
    log_message("POST #{hook.url}\n#{payload.to_json}")
    url = URI.parse(hook.url)
    request = Net::HTTP::Post.new(url.path)
    request.set_form_data({"payload" => payload.to_json})
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == "https"
    response = http.start { |http|
      http.request(request)
    }
    response
  end

  private
  def default_hooks
    [Service.global_hooks, repository.web_hooks].flatten
  end

  def hooks(configured)
    return [repository.web_hooks.detect { |h| h.url == configured }] if !configured.nil?
    default_hooks
  end

  def log_message(message)
    logger.info("#{Time.now.to_s(:short)} #{message}")
  end
end
