require 'spec_helper'

describe Glove::Corpus do
  let(:text) { "the quick brown fox jumped over the lazy dog" }
  let(:opt)  { {window: 3, min_count: 2, stop_words: false} }
  let(:corpus) { described_class.new(text, opt) }

  describe '.build(text, options)' do
    it 'forwards args to #initialize and calls #build_tokens on the instance' do
      expect_any_instance_of(Glove::Corpus).to receive(:build_tokens)

      Glove::Corpus.build(text)
    end
  end

  describe '.new(text, options)' do
    it 'gets parsed tokens from Parser class' do
      expect(corpus.tokens).to be_a Array
    end

    it 'sets options as instance variables' do
      expect(corpus.window).to    eq(opt[:window])
      expect(corpus.min_count).to eq(opt[:min_count])
    end
  end

  describe '#build_tokens' do
    it 'calls #build_count, #build_index, #build_pairs and returns self' do
      expect(corpus).to receive(:build_count)
      expect(corpus).to receive(:build_index)
      expect(corpus).to receive(:build_pairs)
      expect(corpus.build_tokens).to be_instance_of described_class
    end
  end

  describe '#count' do
    it 'constructs a token count hash' do
      expect(corpus.count).to eq({'the' => 2})
    end
  end

  describe '#index' do
    before do
      corpus.build_count
    end

    it 'constructs a token index hash' do
      expect(corpus.index).to eq({'the' => 0})
    end
  end

  describe '#pairs' do
    before do
      corpus.build_count
    end

    it 'constructs array of token pairs with neighbors based on window opt' do
      first_pair = corpus.pairs.first
      last_pair  = corpus.pairs.last

      expect(first_pair.neighbors).to eq %w(quick brown fox)
      expect(last_pair.neighbors).to  eq %w(fox jump over lazi dog)
    end
  end

  describe '#token_neighbors(word, index)' do
    let(:corpus) { described_class.new(text, stop_words: false, min_count: 1) }
    before do
      corpus.build_count
    end

    it "returns window number of neighbors on each side" do
      neighbors = corpus.token_neighbors('jump', 4)
      expect(neighbors).to eq(['brown', 'fox', 'over', 'the'])
    end
  end
end
