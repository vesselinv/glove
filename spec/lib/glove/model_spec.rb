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
    let(:token_index) { {'the' => 0, 'quick' => 1, 'brown' => 2, 'fox' => 3} }
    let(:cooc_matrix) { GSL::Matrix.rand(4,4) }
    let(:trainer)     { double(:train) }
    before do
      allow(model).to receive(:cooc_matrix).and_return(cooc_matrix)
      allow(model).to receive(:token_index).and_return(token_index)
      allow(model).to receive(:train_in_epochs).and_return(trainer)

      model.train
    end

    after(:each) do
      model.train
    end

    it 'creates @word_vec matrix with random floats' do
      expect(model.word_vec.isnull?).to eq(false)
    end

    it 'creates @word_biases vector with zeros' do
      expect(model.word_biases.isnull?).to eq(true)
    end

    it 'calls the #train_in_epochs method' do
      expect(model).to receive(:train_in_epochs)
    end
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
    let(:distances)   { [["electron", 0.98583], ["radiation", 0.99998]] }
    let(:target)      { 'atom' }
    let(:pair_cosine) { 0.99999 }

    before do
      allow(model).to receive(:vector).and_return(0)
      allow(model).to receive(:cosine).and_return(pair_cosine)
      allow(model).to receive(:vector_distance).and_return(distances)
    end

    it 'returns the distances whose diff between the pair distance is less than accuracy arg' do
      words = model.analogy_words('quantum', 'physics', target).flatten

      expect(words).to     include('electron')
      expect(words).not_to include('radiation')
    end
  end

  describe '#most_similar(word, num)' do
    let(:distances) { [["electron", 0.98583], ["radiation", 0.99998]] }

    before do
      allow(model).to receive(:vector_distance).and_return(distances)
    end

    it 'returns closest vectors to given word' do
      words = model.most_similar('atom', 1).flatten

      expect(words).to     include('electron')
      expect(words).not_to include('radiation')
    end
  end

  describe '#train_in_epochs(indices)' do
    let(:worker) { double(:train, run: nil) }
    let(:epochs) { Glove::Model::DEFAULTS[:epochs] }
    before do
      allow(Glove::Workers::TrainingWorker).to receive(:new).and_return(worker)
    end
    it 'calls a traing worker exactly @epochs times' do
      expect(worker).to receive(:run).exactly(epochs).times

      model.send :train_in_epochs, []
    end
  end

  describe '#matrix_nnz' do
    let(:matrix) { GSL::Matrix[[0,9], [3,0]] }

    before do
      allow(model).to receive(:cooc_matrix).and_return(matrix)
    end

    it 'gets all non-zero value indices in the cooc_matrix' do
      nnz = model.send :matrix_nnz
      expect(nnz).to eq([[1,0], [0,1]])
    end
  end
end
