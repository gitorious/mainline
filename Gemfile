source "http://rubygems.org"

gem "rails", "~> 3.0.6"
gem "geoip", "0.8.9"
gem "daemons", "1.1.0", :require => false
gem "rdiscount", "1.3.1.1", :platforms => :ruby
gem "mime-types", "1.16", :require => "mime/types"
gem "diff-lcs", "1.1.2", :require => "diff/lcs"
gem "oauth", "0.4.4"
gem "paperclip", "~> 2.4.5"
gem "state_machine", "0.9.4"
gem "mysql2", "~> 0.3"
gem "activerecord-mysql2-adapter"
gem "acts-as-taggable-on", "2.0.6"
gem "will_paginate", "2.3.15"
gem "just_paginate", "0.0.6"
gem "hodel_3000_compliant_logger", "0.1.0"
gem "net-ldap", "~> 0.3"
gem "capillary", "~> 1.0.1"
gem "nokogiri", "1.5.0"
gem "memcache-client", "~> 1.8"
gem "unicorn", "~> 4.3.1", :platforms => :ruby
gem "exception_notification", :require => "exception_notifier"
gem "bartt-ssl_requirement", "~>1.4.0", :require => "ssl_requirement"
gem "validates_url_format_of", "~> 0.2.0"
gem "thinking-sphinx", "~> 2.0.10"
gem "ruby-hmac", "0.4.0", :platforms => :ruby_18

# TODO: I suspect these gems can be removed.
# Make all tests pass before attempting.
group :deprecations do
  gem "chronic", "0.3.0"
  gem "hoe", "2.8.0", :require => false
  gem "echoe", "4.3.1", :require => false
end

group :openid do
  gem "ruby-yadis", "0.3.4", :require => "yadis"
  gem "ruby-openid", :require => "openid"
  gem "gitorious_openid_auth", "~> 1.1"
end

group :test do
  gem "mocha", "0.9.10", :require => false
  gem "factory_girl_rails", "~> 4.1"
  gem "shoulda", "~> 2.9.1"
  gem "rots", :git => "https://github.com/roman/rots.git"
  gem "capybara", "1.0.1"
  gem "launchy", "2.0.5" # used only for Capybara's save_and_open_page for launching the browser
end

group :development do
  gem "foreman", "~> 0.41"
  gem "thin", "~> 1.2"
end

group :git_proxy do
  gem "proxymachine", "1.2.4"
  gem "rake", "~> 0.9"
end

group :messaging do
  gem "json", "~> 1.5.1", :platforms => :ruby_18
end

group :resque do
  gem "resque", "1.9.8"
end

platform :jruby do
  gem "activerecord-jdbcmysql-adapter"
end
