# Ruby GloVe

[![Code Climate](https://codeclimate.com/github/vesselinv/glove/badges/gpa.svg)](https://codeclimate.com/github/vesselinv/glove)
[![Test Coverage](https://codeclimate.com/github/vesselinv/glove/badges/coverage.svg)](https://codeclimate.com/github/vesselinv/glove)
[![Build Status](https://travis-ci.org/vesselinv/glove.svg)](https://travis-ci.org/vesselinv/glove)

Ruby implementation of Global Vectors for Word Representations.

## Overview

GloVe is an unsupervised learning algorithm for obtaining vector representations for words. Training is performed on aggregated global word-word co-occurrence statistics from a corpus, and the resulting representations showcase interesting linear substructures of the word vector space.

**NOTE** This is an early prototype.

## Resources

- [Documentation](http://www.rubydoc.info/github/vesselinv/glove)
- [Academic Paper on Global Vectors](http://nlp.stanford.edu/projects/glove/glove.pdf)
- [Original C Implementation](http://nlp.stanford.edu/projects/glove/)
- [glove-python](https://github.com/maciejkula/glove-python)
- [spark-glove](https://github.com/petro-rudenko/spark-glove)

## Dependencies

This library relies on the [rb-gsl](http://blackwinter.github.io/rb-gsl) gem for Matrix and Vector operations, therefore you need GNU Scientific Library installed.

Linux:

    $ sudo apt-get install libgsl0-dev

OS X:

    $ brew install gsl

## Installation

Not yet submitted to rubygems.org so clone and run `bundle install`

## Usage

```ruby
require 'glove'

model = Glove::Model.new

# Next feed it some text.

text = File.read('quantum-physics.txt')
model.fit(text)

# Or you can pass it a Glove::Corpus object as the text argument instead
corpus = Glove::Corpus.build(text)
model.fit(corpus)

# Finally, to query the model, we need to train it

model.train

# So far, word similarity and analogy task methods have been included:

# Most similar words to physics
model.most_similar('physics', 1) # => {"quantum"=>0.9967993356234444}

# What words relate to atom like quantum relates to physics?

model.analogy_words('quantum', 'physics', 'atom') # => {"electron"=>0.9858380292886947, "energi"=>0.9815122410243475, "photon"=>0.9665073849076669}

# Save the trained matrices and vectors for later usage in bianry formats

model.save('corpus.bin', 'cooc-matrix.bin', 'word-vec.bin', 'word-biases.bin')

# Later on create a new onstance and call #load

model = Glove::Model.new
model.load('corpus.bin', 'cooc-matrix.bin', 'word-vec.bin', 'word-biases.bin')
```

## TODO

- Improve test coverage
- Perform test and benchmark with texts containing more than 25K words.
- Saving/loading of matrix and vector files
- Word Vector graphs
- Add stop words filtering in Glove::Parser

## Contributing

1. Fork it ( https://github.com/vesselinv/glove/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
