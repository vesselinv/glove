if ENV['CI']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require 'rspec'
require 'glove'

RSpec.configure do |c|
  c.mock_with :rspec
end

def fixtures_path
  File.expand_path File.join(File.dirname(__FILE__), 'fixtures')
end
