if ENV['COVERAGE'] && RUBY_VERSION > '1.9'
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::RcovFormatter
  ]

  SimpleCov.start do
    add_filter '/test/'
    add_filter '/vendor/'

    add_group 'Models',         'app/models'
    add_group 'Controllers',    'app/controllers'
    add_group 'Helpers',        'app/helpers'
    add_group 'Use Cases',      'app/use_cases'
    add_group 'Commands',       'app/commands'
    add_group 'Pre-Conditions', 'app/pre_conditions'
    add_group 'Validators',     'app/validators'
    add_group 'Processors',     'app/processors'
    add_group 'Serializers',    'app/serializers'
    add_group 'Presenters',     'app/presenters'
  end
end
