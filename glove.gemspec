# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'glove/version'

Gem::Specification.new do |spec|
  spec.name          = "glove"
  spec.version       = Glove::VERSION
  spec.authors       = ["Veselin Vasilev"]
  spec.email         = ["vesselinv@me.com"]
  spec.summary       = %q{Global Vectors for Word Representation}
  spec.description   = %q{GloVe is an unsupervised learning algorithm for obtaining vector representations for words. Training is performed on aggregated global word-word co-occurrence statistics from a corpus, and the resulting representations showcase interesting linear substructures of the word vector space. This is a pure Ruby implementation of GloVe utilizing GSL.}
  spec.homepage      = "https://github.com/vesselinv/glove"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_dependency "fast-stemmer"
end
