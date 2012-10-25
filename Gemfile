source "http://rubygems.org"

gem "rails", "3.0.6"
gem "chronic", "0.3.0"
gem "geoip", "0.8.9"
gem "daemons", "1.1.0", :require => false
gem "hoe", "2.8.0", :require => false
gem "echoe", "4.3.1", :require => false
gem "ruby-yadis", "0.3.4", :require => "yadis"
gem "ruby-openid", :require => "openid"
gem "rdiscount", "1.3.1.1", :platforms => :ruby
gem "mime-types", "1.16", :require => "mime/types"
gem "diff-lcs", "1.1.2", :require => "diff/lcs"
gem "oauth", "0.4.4"
gem "paperclip", "~> 2.4.5"
gem "state_machine", "0.9.4"
gem "riddle", "1.2.2" # For the ultrasphinx plugin
gem "mysql", "2.8.1", :platforms => :ruby
gem "acts-as-taggable-on", "2.0.6"
gem "will_paginate", "2.3.15"
gem "just_paginate", "0.0.6"
gem "hodel_3000_compliant_logger", "0.1.0"
gem "net-ldap", "~> 0.3"
gem "capillary", "~> 1.0.1"
gem "nokogiri", "1.5.0"
gem "memcache-client", "~> 1.8"
gem "unicorn", "~> 4.3.1", :platforms => :ruby

# Rails 2
# gem "exception_notification", "~> 1.0.20090728", :require => 'exception_notifier'
# gem "revo-ssl_requirement", "1.1.0"

gem "exception_notification", :require => 'exception_notifier'
gem "bartt-ssl_requirement", '~>1.4.0', :require => 'ssl_requirement'

# Ruby 1.8 gems
gem "ruby-hmac", "0.4.0", :platforms => :ruby_18

group :test do
  gem "mocha", "0.9.10", :require => false
  gem "factory_girl", "~> 1.3.0"
  gem "shoulda", "~> 2.9.1"
  gem "tuxml", "0.0.1"
  gem "rots", :git => 'https://github.com/roman/rots.git'
  gem "capybara", "1.0.1"
  gem "launchy", "2.0.5" # used only for Capybara's save_and_open_page for launching the browser
end

group :development do
  gem "foreman", "~> 0.41"
  gem "stompserver", "~> 0.9"
  gem "thin", "~> 1.2"
end

group :git_proxy do
  gem "proxymachine", "1.2.4"
  gem "rake", "0.8.7"
end

group :messaging do
  gem "json", "~> 1.5.1", :platforms => :ruby_18
end

group :resque do
  gem "resque", "1.9.8"
end

group :stomp do
  gem "stomp", "1.1"
end

group :active_messaging do
  gem "activemessaging", "0.7.1"
end

platform :jruby do
  gem "activerecord-jdbcmysql-adapter"
end
