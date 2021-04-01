require 'byebug'
require 'rspec'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

if ENV['CI'] == 'true' || ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'meddleware'

RSpec.configure do |config|
  # allow 'fit' examples
  config.filter_run_when_matching :focus
end
