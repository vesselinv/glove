require 'glove/version'
require 'gsl'
require 'fast_stemmer'
require 'parallel'
require 'core_ext/float'

module Glove
  # Return the root path of the gem
  # @return [String] the full path to the gem
  def self.root_path
    File.expand_path File.join(File.dirname(__FILE__), '../')
  end
end

require 'glove/token_pair'
require 'glove/parser'
require 'glove/corpus'
require 'glove/workers'
require 'glove/model'
