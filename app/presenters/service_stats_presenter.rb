# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class ServiceStatsPresenter
  attr_reader :service

  def initialize(service)
    @service = service
    @adapter = service.adapter
  end

  def user
    service.user
  end

  def to_param
    service.to_param
  end

  def runs
    span("gts-pos", service.successful_request_count) + "/" + span("gts-neg", service.failed_request_count)
  end

  def last_response
    last_response = service.last_response
    status_code = last_response.to_i
    successful = (200..299)
    error = (400..599)

    case status_code
    when successful
      strong("gts-pos", last_response)
    when error
      strong("gts-neg", last_response)
    else
      last_response
    end
  end

  private

  def span(klass, content)
    tag("span", klass, content)
  end

  def strong(klass, content)
    tag("strong", klass, content)
  end

  def tag(tag_name, klass, content)
    %Q[<#{tag_name} class="#{klass}">].html_safe + content.to_s + "</#{tag_name}>".html_safe
  end

  def method_missing(name, *args, &block)
    @adapter.send(name, *args, &block)
  end
end
