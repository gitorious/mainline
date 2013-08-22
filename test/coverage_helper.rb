if ENV['COVERAGE'] && RUBY_VERSION > "1.9"
  require "simplecov"
  require "simplecov-rcov"

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::RcovFormatter
  ]

  SimpleCov.start("rails") do
    add_filter '/test/'
    add_filter '/vendor/'
  end
end
