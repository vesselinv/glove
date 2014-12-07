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

  context "IO" do
    let(:corpus) { Glove::Corpus.build('quick brown fox', min_count: 1, stop_words: false) }
    let(:cooc)   { GSL::Matrix.zeros(3,3) }
    let(:words)  { GSL::Matrix.zeros(3, Glove::Model::DEFAULTS[:num_components]) }
    let(:biases) { GSL::Vector.alloc([1,2,3]) }

    describe '#save' do
      let(:files)  do
        %w(corpus.bin cooc.bin words.bin biases.bin).map do |f|
          File.join(fixtures_path, f)
        end
      end

      before(:each) do
        model.instance_variable_set(:@cooc_matrix, cooc)
        model.instance_variable_set(:@corpus, corpus)
        model.instance_variable_set(:@word_vec, words)
        model.instance_variable_set(:@word_biases, biases)
      end

      it "dumps corpus, cooc_matrix, word_vec and word_biases to files" do
        model.save(*files)

        files.each do |file|
          expect(File.size(file)).to be > 0
        end

        files.each{ |f| File.delete(f) }
      end
    end

    describe '#load' do
      let(:files)  do
        %w(corpus-t.bin cooc-t.bin words-t.bin biases-t.bin).map do |f|
          File.join(fixtures_path, f)
        end
      end

      before(:each) do
        model.load(*files)
      end

      it 'loads corpus data from file as first argument' do
        expect(model.corpus.tokens).to eq(corpus.tokens)
      end

      it 'loads cooc_matrix data from file as second argument' do
        expect(model.cooc_matrix).to eq(cooc)
      end

      it 'loads word_vec data from file as third argument' do
        expect(model.word_vec).to eq(words)
      end

      it 'loads word_biases data from file as fourth argument' do
        expect(model.word_biases).to eq(biases)
      end
    end
  end

  describe '#visualize' do
    pending
  end

  describe '#analogy_words(word1, word2, target, num, accuracy)' do
    pending
  end

  describe '#most_similar(word, num)' do
    pending
  end
end
