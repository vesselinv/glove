# Ruby GloVe

[![Build Status](https://travis-ci.org/vesselinv/glove.svg)](https://travis-ci.org/vesselinv/glove)
[![Code Climate](https://codeclimate.com/github/vesselinv/glove/badges/gpa.svg)](https://codeclimate.com/github/vesselinv/glove)
[![Test Coverage](https://codeclimate.com/github/vesselinv/glove/badges/coverage.svg)](https://codeclimate.com/github/vesselinv/glove)
[![Inline docs](http://inch-ci.org/github/vesselinv/glove.svg?branch=master)](http://inch-ci.org/github/vesselinv/glove)

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

Only compatible with MRI: tested in versions 2.0.x and 2.1.x

## Installation

```
$ gem install glove
```

or add to your Gemfile

```ruby
gem 'glove'
```

## Usage

```ruby
require 'glove'

# See documentation for all available options
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
# Most similar words to quantum
model.most_similar('quantum')
# => [["physic", 0.9974459436353388], ["mechan", 0.9971606266531394], ["theori", 0.9965966776283189]]

# What words relate to atom like quantum relates to physics?
model.analogy_words('quantum', 'physics', 'atom')
# => [["electron", 0.9858380292886947], ["energi", 0.9815122410243475], ["photon", 0.9665073849076669]]

# Save the trained matrices and vectors for later usage in binary formats
model.save('corpus.bin', 'cooc-matrix.bin', 'word-vec.bin', 'word-biases.bin')

# Later on create a new instance and call #load
model = Glove::Model.new
model.load('corpus.bin', 'cooc-matrix.bin', 'word-vec.bin', 'word-biases.bin')
# Now you can query the model again and get the same results as above
```

# Performance

Thanks to the [rb-gsl](https://github.com/blackwinter/rb-gsl) bindings for
[GSL](https://www.gnu.org/software/gsl/), matrix/vector operations are fast. The
glove algorythm itself, however, requires quite a bit of computational power, even
the original C library. If you need speed, use smaller texts with vocabulaty size
no more than 100K words. Processing text with 160K words (compilation of several
books on quantum mechanics) on a late 2012 MBP (8GB RAM) with ruby-2.1.5 takes
about 7 minutes:

     $ ruby -Ilib benchmark/benchmark.rb
                     user     system      total        real
    Fit Text    11.320000   0.070000  11.390000 ( 11.387612)
    Vocabulary size: 158323
    Unique tokens: 2903
    Co-occur     1.330000   0.250000 1107.720000 (300.738453)
    Train      121.120000  12.960000  134.080000 (128.409034)
    Similarity   0.010000   0.000000    0.010000 (  0.057423)
    Give me the 3 most similar words to quantum
    [["problem", 0.9977609386134489], ["mechan", 0.9977529272587808], ["classic", 0.9974759411408415]]
    Analogy      0.010000   0.000000   0.010000 (  0.010674)
    What 3 words relate to atom like quantum relates to mechanics?
    [["particl", 0.9982711579369483], ["find", 0.9982303885530384], ["expect", 0.9982017117355527]]


## TODO

- Word Vector graphs

## Contributing

1. Fork it ( https://github.com/vesselinv/glove/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
