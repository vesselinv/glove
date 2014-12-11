require 'spec_helper'

describe Glove::Workers::TrainingWorker do
  let(:text)    { 'quick fox brown fox' }
  let(:opt)     { {min_count: 1, stop_words: false, threads: 1} }
  let(:model)   { Glove::Model.new(opt).fit(text) }
  let(:index)   { model.send(:matrix_nnz)[0] }
  let(:worker)  { described_class.new(model, [index]) }

  describe '.new' do
    it 'dupes caller\'s :word_vec attribute ' do
      expect(worker.word_vec).to eq(model.word_vec)
    end

    it 'dupes caller\'s :word_biases attribute ' do
      expect(worker.word_biases).to eq(model.word_biases)
    end
  end

  describe '#run' do
    before do
      allow(worker).to receive(:work)
    end

    it 'runs the #work method :threads number of times' do
      expect(worker).to receive(:work).exactly(opt[:threads]).times
      worker.run
    end

    it 'returns array of :word_vec and :word_biases after running the transforms' do
      expect(worker.run).to eq([model.word_vec, model.word_biases])
    end
  end

  describe '#work' do
    let(:loss) { 1 }
    let(:word_a_norm) { 1 }
    let(:word_b_norm) { 1 }

    before do
      allow(worker).to receive(:calc_weights).with(index[0], index[1]).
                        and_return([loss, word_b_norm, word_b_norm])
    end

    it 'calculates loss, and norm for each matrix index and applies the new values' do
      expect(worker).to receive(:calc_weights).exactly(1).times
      expect(worker).to receive(:apply_weights).
        with(index[0], index[1], loss, word_a_norm, word_b_norm)

      worker.work([index], Mutex.new)
    end
  end

  describe '#calc_weights' do
    it 'performs the calculation and returns loss and norm' do
      loss, norm1, norm2 = worker.calc_weights(index[0], index[1])

      expect(loss).not_to eq(0)
      expect(loss).not_to eq(norm1)
      expect(loss).not_to eq(norm2)
    end
  end

  describe '#apply_weights' do
    before do
      worker.apply_weights(index[0], index[1], 1, 1, 1)
    end

    it "applies weights on the :word_vec matrix" do
      expect(worker.word_vec[0,0]).not_to eq(model.word_vec[0,0])
    end

    it 'applied loss reducation on :word_biases' do
      bias1 = worker.word_biases[index[0]]
      bias2 = worker.word_biases[index[1]]
      model_bias1 = model.word_biases[index[0]]
      model_bias2 = model.word_biases[index[1]]

      expect(bias1).not_to eq(model_bias1)
      expect(bias2).not_to eq(model_bias2)
    end
  end
end
