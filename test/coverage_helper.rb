if ENV['COVERAGE'] && RUBY_VERSION > "1.9"
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start("rails")
end
