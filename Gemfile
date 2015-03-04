source "https://rubygems.org"

gem "rails", "3.2.21"
gem "geoip", "0.8.9"
gem "daemons", "1.1.0", :require => false
gem "rdiscount", "~> 2.1.7"
gem "mime-types", "~> 1.16", :require => "mime/types"
gem "diff-lcs", "1.1.2", :require => "diff/lcs"
gem "oauth", "0.4.4"
gem "paperclip", "~> 3.5.2"
gem "state_machine", "~> 1.1", :git => "https://github.com/gitorious/state_machine.git"
gem "acts-as-taggable-on", "~> 3.4"
gem "will_paginate", "~>3.0"
gem "just_paginate", "0.2.2"
gem "net-ldap", "~> 0.11"
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
gem "virtus", '~> 1.0.1'
gem "charlatan", '~> 0.0.1'
gem "rake", "~> 10.0"
gem "gitlab-grit", :require => "grit", :git => "https://github.com/gitorious/grit.git"
gem "bugsnag"
gem "simple_form", "~> 2.1"
gem "force_utf8"
gem 'rugged', git: 'https://github.com/libgit2/rugged.git', branch: 'development', submodules: true
gem 'react-rails', '~> 0.9.0'
gem 'pundit', '~> 0.2.3'
gem "redcarpet", '~> 3.0.0'
gem "skylight"
gem "unicorn-worker-killer"

if ENV['GTS_ENGINE'].to_s != 'true'
  gem "gitorious-issues", :git => "https://git.gitorious.org/gitorious/gitorious-issues.git", :branch => 'master'
end

group :openid do
  gem "ruby-openid", :require => "openid"
  gem "gitorious_openid_auth", "~> 1.1", :require => "open_id_authentication"
end

group :test do
  gem "minitest", "~> 4.7", :require => false
  gem "minitest-rails-capybara", "~> 0.10", :require => false
  gem "minitest-reporters", "~> 0.14", :require => false

  gem "capybara", "~> 2.1", :require => false
  gem "capybara_minitest_spec", "~> 1.0", :require => false
  gem "capybara-screenshot", :require => false
  gem "poltergeist", "~> 1.4", :require => false

  gem "shoulda", "~> 3.3"
  gem "database_cleaner"

  gem "guard-minitest"
  gem "guard-ctags-bundler"

  gem "mocha", "0.13.3", :require => false
  gem "webmock", "~> 1.13"
  gem "factory_girl_rails", "~> 1.7"

  gem "ci_reporter"
  gem "simplecov", :platforms => [:ruby_19, :ruby_20], :require => false
  gem "simplecov-rcov", :platforms => [:ruby_19, :ruby_20], :require => false

  gem "zeus"
end

group :postgres do
  gem "pg", :platforms => :ruby
end

group :development do
  gem "foreman", "~> 0.41"
  gem "thin", "~> 1.2"
  gem "pry-rails"
  gem "quiet_assets"
end

group :ldap_wizard do
  gem "sinatra-contrib"
  gem "makeup"
end

group :git_proxy do
  gem "proxymachine", "1.2.4"
end

group :resque do
  gem "resque", "1.25.2"
  gem "resque-cleaner"
  gem "resque-job-stats"
end

group :http_utils do
  gem "httparty", "~> 0.9"
end

platform :jruby do
  gem "activerecord-jdbcmysql-adapter"
  gem "jruby-openssl"
  gem 'trinidad', :require => false
end

group :dolt do
  gem "libdolt", "~> 0.34.0"
  gem "dolt", "~> 0.30.0"
  gem "tiltout", "~> 1.4"

  # Markup formats
  gem "RedCloth"
  gem "rdoc"
  gem "org-ruby"
  gem "creole"
  gem "wikicloth"
  gem "asciidoctor"
end

group :assets do
  gem "sass-rails", "~> 3.2"
end
