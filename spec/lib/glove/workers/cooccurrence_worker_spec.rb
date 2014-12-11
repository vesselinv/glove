require 'spec_helper'

describe Glove::Workers::CooccurrenceWorker do
  let(:index) { {'quick' => 0, 'brown' => 1, 'fox' => 2} }
  let(:pairs) do
    index.map{ |w,i| Glove::TokenPair.new(w) }
  end
  let(:threads) { 0 }
  let(:caller) do
    double(:caller, token_index: index, token_pairs: pairs, threads: threads)
  end
  let(:worker) { described_class.new(caller) }

  describe '.new' do
    it "keeps reference of the caller class" do
      expect(worker.instance_variable_get(:@caller)).to eq(caller)
    end

    it "dupes token_index off the caller" do
      expect(worker.token_index).to eq(index)
    end

    it "dupes token_pairs off the caller" do
      expect(worker.token_pairs).to eq(pairs)
    end
  end

  describe '#threads' do
    it "delegates method to @caller" do
      expect(worker.threads).to eq(threads)
    end
  end

  describe '#run' do
    before do
      allow(worker).to receive(:build_cooc_matrix_col).and_return([0,1,2,3])
    end

    it 'calls #build_cooc_matrix_col in parallel processes' do
      expect(worker).to receive(:build_cooc_matrix_col).exactly(index.size).times
      worker.run
    end

    it 'converts the vector results into a matrix' do
      expect(worker.run).to be_a GSL::Matrix
    end
  end

  describe '#build_cooc_matrix_col' do
    before do
      pairs[0].neighbors << 'fox'
    end

    it 'builds the vector co-occurrence representation of a given token' do
      result = worker.build_cooc_matrix_col(['fox', 2])

      expect(result.size).to eq(index.size)
      expect(result[0]).to eq(1)
    end
  end
end
