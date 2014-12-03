require 'spec_helper'

describe Glove::TokenPair do
  let(:token) { 'fox' }
  let(:neighbors) { ['brown', 'jump'] }
  let(:pair) { Glove::TokenPair.new(token, neighbors) }

  describe '.new(word, neighbors)' do
    it 'sets the token and neighbors variables' do
      expect(pair.token).to     eq(token)
      expect(pair.neighbors).to eq(neighbors)
    end
  end
end
