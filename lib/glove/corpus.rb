module Glove
  # Class responsible for building the token count, token index and token pairs
  # hashes from a given text
  class Corpus
    # @!attribute [r] tokens
    #   @return [Fixnum] Returns the parsed tokens array. Holds all the tokens
    #     in the exact order they appear in the text
    attr_reader :tokens, :window, :min_count

    # Convenience method for creating an instance and building the token count,
    # index and pairs (see #initialize)
    def self.build(text, options={})
      new(text, options).build_tokens
    end

    # Create a new {Glove::Corpus} instance
    #
    # @param [Hash] options the options to initialize the instance with.
    # @option options [Integer] :window (2) Number of context words to the left
    #   and to the right
    # @option options [Integer] :min_count (5) Lower limit such that words which
    #   occur fewer than :min_count times are discarded.
    def initialize(text, options={})
      @tokens = Parser.new(text, options).tokenize
      @window = options[:window] || 2
      @min_count = options[:min_count] || 5
    end

    # Builds the token count, token index and token pairs
    #
    # @return [Glove::Corpus]
    def build_tokens
      build_count
      build_index
      build_pairs
      self
    end

    # Hash that stores the occurence count of unique tokens
    #
    # @return [Hash{String=>Integer}] Token-Count pairs where count is total occurences of
    #   token in the (non-unique) tokens hash
    def count
      @count ||= tokens.inject(Hash.new(0)) do |hash,item|
        hash[item] += 1
        hash
      end.to_h.keep_if{ |word,count| count >= min_count }
    end

    # A hash whose values hold the senquantial index of a word as it appears in
    # the #count hash
    #
    # @return [Hash{String=>Integer}] Token-Index pairs where index is the sequential index
    #   of the token in the unique vocabulary pool
    def index
      @index ||= @count.keys.each_with_index.inject({}) do |hash,(word,idx)|
        hash[word] = idx
        hash
      end
    end

    # Iterates over the tokens array and contructs {Glove::TokenPair}s where
    # neighbors holds the adjacent (context) words. The number of neighbours is
    # controller by the :window option (on each side)
    #
    # @return [Array<(Glove::TokenPair)>] Array of {Glove::TokenPair}s
    def pairs
      @pairs ||= tokens.map.with_index do |word, index|
        next unless count[word] >= min_count

        pair      = TokenPair.new(word, [])
        start_pos = index - window < 0 ? 0 : index - window
        end_pos   = (index + window >= tokens.size) ? tokens.size - 1 : index + window

        tokens[start_pos..end_pos].each do |word2|
          next if word == word2
          pair.neighbors << word2
        end

        pair
      end.compact
    end

    alias_method :build_index, :index
    alias_method :build_count, :count
    alias_method :build_pairs, :pairs
  end
end
