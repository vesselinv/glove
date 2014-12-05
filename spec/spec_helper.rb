if ENV['CI']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require 'rspec'
require 'glove'

RSpec.configure do |c|
  c.mock_with :rspec
end
