require 'spec_helper'

describe Glove::Parser do
  let(:text) { "the quick brown Fx jumps over the lazy d0g" }
  let(:parser) { described_class.new(text) }

  describe '#tokenize' do
    let(:tokens) { %w(the quick brown jump over the lazi) }

    it "tokenizes the text string" do
      expect(parser.tokenize).to eq(tokens)
    end
  end

  describe '#downcase' do
    it "downcases all letters" do
      expect(parser.downcase).to eq text.downcase
    end
  end

  describe '#split' do
    it "splits the text string into an array" do
      expect(parser.split).to be_a Array
    end
  end

  describe '#alphabetic' do
    it "leaves only words that do not contain any numbers" do
      expect(parser.alphabetic).not_to include('b2b')
    end
  end

  describe '#stem' do
    it "stemps all words in the text array" do
      parser.split

      expect(parser.stem).not_to include('jumps')
      expect(parser.stem).to     include('jump')
    end
  end

  describe '#normalize' do
    it "removes words whose length if not within specified boundary" do
      parser.split

      expect(parser.normalize).not_to include('Fx')
    end
  end
end
