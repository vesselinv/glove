require 'spec_helper'

describe Glove::Model do
  let(:model) { Glove::Model.new }

  describe '.new(options)' do
    it 'sets options as instance variables' do
      expect(model.threads).to eq(Glove::Model::DEFAULTS[:threads])
    end

    it 'sets cooc_matrix, word_vec and Word_biases to nil' do
      expect(model.cooc_matrix).to be_nil
      expect(model.word_vec).to    be_nil
      expect(model.word_biases).to be_nil
    end
  end

  describe '#fit(text)' do
    before do
      allow(model).to receive(:build_cooc_matrix)
      model.fit('the quick brown fox jumped over the lazy dog')
    end

    it "build a corpus object from text string argument" do
      expect(model.corpus).to be_instance_of Glove::Corpus
    end

    it "sets @token_index and @token_pairs vars" do
      expect(model.token_pairs).not_to be_nil
      expect(model.token_index).not_to be_nil
    end
  end

  describe '#train' do
    pending
  end

  describe '#save' do
    pending
  end

  describe '#load' do
    pending
  end

  describe '#vizualize' do
    pending
  end

  describe '#analogy_words(word1, word2, target, num, accuracy)' do
    pending
  end

  describe '#most_similar(word, num)' do
    pending
  end
end
