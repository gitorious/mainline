# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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

ActionMailer::Base.default_url_options[:protocol] = Gitorious.scheme
ActionMailer::Base.default_url_options[:host]     = Gitorious.host
ActionMailer::Base.default_url_options[:port]     = Gitorious.port unless Gitorious.default_port?

# Can intercept and override emails like this
# Mail.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?

smtp_config_path = (Rails.root + 'config' + 'smtp.yml').to_s
if File.exist?(smtp_config_path)
  smtp_settings = Gitorious::ConfigurationReader.read(smtp_config_path)
  if smtp_settings
    ActionMailer::Base.smtp_settings = smtp_settings.symbolize_keys
  end
end
