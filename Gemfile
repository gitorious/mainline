source "http://rubygems.org"

gem "rails", "3.2.12"
gem "geoip", "0.8.9"
gem "daemons", "1.1.0", :require => false
gem "rdiscount", "~> 1.6"
gem "mime-types", "~> 1.16", :require => "mime/types"
gem "diff-lcs", "1.1.2", :require => "diff/lcs"
gem "oauth", "0.4.4"
gem "paperclip", "~> 2.7"
gem "state_machine", "~> 1.1"
gem "acts-as-taggable-on", "~> 2.3"
gem "will_paginate", "~>3.0"
gem "just_paginate", "0.1"
gem "net-ldap", "~> 0.3"
gem "capillary", "~> 1.0.1"
gem "nokogiri", "~> 1.5", "< 1.6"
gem "memcache-client", "~> 1.8"
gem "unicorn", "~> 4.3.1", :platforms => :ruby
gem "exception_notification", :require => "exception_notifier"
gem "thinking-sphinx", "~> 3.0"
gem "rails_autolink", "~> 1.0"
gem "mysql2", :platforms => :ruby
gem "highline"
gem "use_case", "~> 0.13"
gem "virtus", :git => "https://github.com/solnic/virtus.git"
gem "rake", "~> 10.0"

group :openid do
  gem "ruby-yadis", "0.3.4", :require => "yadis"
  gem "ruby-openid", :require => "openid"
  gem "gitorious_openid_auth", "~> 1.1", :require => "open_id_authentication"
end

group :test do
  gem "mocha", "0.9.10", :require => false
  gem "factory_girl_rails", "~> 1.7"
  gem "shoulda", "~> 3.3"
  gem "shoulda-matchers", "~> 1.4", :platforms => :ruby_18
  gem "minitest", "4.2.0"
  gem "ci_reporter"
  gem "rcov", :platforms => :ruby_18
  gem "simplecov", :platforms => [:ruby_19, :ruby_20]
  gem "simplecov-rcov", :platforms => [:ruby_19, :ruby_20]
  gem "guard-minitest", :git => "https://github.com/psyho/guard-minitest.git", :branch => 'include-paths'
  gem "guard-ctags-bundler"
  gem "zeus", "0.13.4.pre2"
  gem "webmock"
end

group :postgres do
  gem "pg", :platforms => :ruby
end

group :development do
  gem "better_errors", :platforms => [:ruby_19, :ruby_20]
  gem "binding_of_caller" , :platforms => [:ruby_19, :ruby_20]
  gem "foreman", "~> 0.41"
  gem "thin", "~> 1.2"
end

group :git_proxy do
  gem "proxymachine", "1.2.4"
end

group :messaging do
  gem "json", ">= 1.7.7", "< 1.8", :platforms => :ruby_18
end

group :resque do
  gem "resque", "~> 1.23"
end

group :http_utils do
  gem "httparty", "~> 0.9"
end

platform :jruby do
  gem "activerecord-jdbcmysql-adapter"
  gem "jruby-openssl"
  gem 'trinidad', :require => false
end

platform :ruby_18 do
  gem "ruby-hmac", "0.4.0"
  gem "oniguruma", "~> 1.1"
  gem "SystemTimer", "~> 1.2"
end

group :dolt do
  gem "libdolt", "~> 0.28"
  gem "dolt", "~> 0.28"
  gem "tiltout", "~> 1.4"

  # Markup formats
  gem "redcarpet"
  gem "RedCloth"
  gem "rdoc"
  gem "org-ruby"
  gem "creole"
  gem "wikicloth"
end
