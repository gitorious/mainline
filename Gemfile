source "https://rubygems.org"

gem "rails", "3.2.14"
gem "geoip", "0.8.9"
gem "daemons", "1.1.0", :require => false
gem "rdiscount", "~> 1.6"
gem "mime-types", "~> 1.16", :require => "mime/types"
gem "diff-lcs", "1.1.2", :require => "diff/lcs"
gem "oauth", "0.4.4"
gem "paperclip", "~> 3.5.2"
gem "state_machine", "~> 1.1"
gem "acts-as-taggable-on", "~> 2.3"
gem "will_paginate", "~>3.0"
gem "just_paginate", "0.2.2"
gem "net-ldap", "~> 0.3"
gem "capillary", "~> 1.0.1"
gem "nokogiri", "~> 1.5", "< 1.6"
gem "memcache-client", "~> 1.8"
gem "unicorn", "~> 4.6.3", :platforms => :ruby
gem "exception_notification", :require => false
gem "thinking-sphinx", "~> 3.0"
gem "rails_autolink", "~> 1.0"
gem "mysql2", :platforms => :ruby
gem "highline"
gem "use_case"
gem "virtus", '~> 1.0.0'
gem "rake", "~> 10.0"
gem "gitlab-grit", :require => "grit", :git => "https://github.com/wrozka/grit.git"
gem "airbrake", "~> 3.1.14", :require => false
gem "simple_form", "~> 2.1"
gem "force_utf8"

group :openid do
  gem "ruby-openid", :require => "openid"
  gem "gitorious_openid_auth", "~> 1.1", :require => "open_id_authentication"
end

group :test do
  gem "mocha", "0.13.3", :require => false
  gem "factory_girl_rails", "~> 1.7"
  gem "shoulda", "~> 3.3"
  gem "shoulda-matchers", "~> 1.4", :platforms => :ruby_18
  gem "minitest", "4.2.0"
  gem "ci_reporter"
  gem "rcov", :platforms => :ruby_18
  gem "simplecov", :platforms => [:ruby_19, :ruby_20], :require => false
  gem "simplecov-rcov", :platforms => [:ruby_19, :ruby_20], :require => false
  gem "guard-minitest"
  gem "guard-ctags-bundler"
  gem "zeus", "0.13.4.pre2"
  gem "webmock"
  gem "capybara", "~> 2.1"
  gem "capybara_minitest_spec", "~> 1.0"
  gem "capybara-screenshot"
  gem "poltergeist", "~> 1.4"
  gem "database_cleaner"
end

group :postgres do
  gem "pg", :platforms => :ruby
end

group :development do
  gem "binding_of_caller" , :platforms => [:ruby_19, :ruby_20]
  gem "foreman", "~> 0.41"
  gem "thin", "~> 1.2"
  gem "sinatra-contrib"
  gem "pry-rails"
  gem "debugger"
end

group :git_proxy do
  gem "proxymachine", "1.2.4"
end

group :messaging do
  gem "json", ">= 1.7.7", "< 1.8", :platforms => :ruby_18
end

group :resque do
  gem "resque", "~> 1.23"
  gem "resque-cleaner", "~> 0.2.11"
  gem "resque-job-stats", "~> 0.3.0"
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
  gem "libdolt", "~> 0.33.7"
  gem "dolt", "~> 0.30.0"
  gem "tiltout", "~> 1.4"

  # Markup formats
  gem "redcarpet"
  gem "RedCloth"
  gem "rdoc"
  gem "org-ruby"
  gem "creole"
  gem "wikicloth"
end
