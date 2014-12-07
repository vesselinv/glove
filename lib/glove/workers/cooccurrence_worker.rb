module Glove
  module Workers
    # Constructs the co-occurrence matrix for {Glove::Model}
    class CooccurrenceWorker
      extend ::Forwardable

      # @!attribute [r] token_index
      #   @return [Hash{String=>Integer}] Clone of @parent.token_index
      # @!attribute [r] word_biases
      #   @return [Array<(Glove::TokenPair)>] Clone of @parent.token_pairs
      attr_reader :token_index, :token_pairs

      def_delegators :@parent, :threads

      # Creates instance of the class
      #
      # @param [Glove::Model] parent Caller class
      def initialize(klass)
        @parent = klass
        @token_index = @parent.token_index.dup
        @token_pairs = @parent.token_pairs.dup
      end

      # Perform the building of the matrix
      def run
        vectors = Parallel.map(token_index, in_processes: threads) do |slice|
          build_cooc_matrix_col(slice)
        end

        GSL::Matrix.alloc(*vectors)
      end

      # Creates a vector column for the cooc_matrix based on given token.
      # Calculates sum for how many times the word exists in the constext of the
      # entire vocabulary
      #
      # @param [Array<(String, Integer)>] slice Token with index
      # @return [Array] GSL::Vector#to_a
      def build_cooc_matrix_col(slice)
        token = slice[0]
        vector = GSL::Vector.alloc(token_index.size)

        token_pairs.each do |pair|
          key = token_index[pair.token]
          sum = pair.neighbors.select{ |word| word == token }.size
          vector[key] += sum
        end

        vector.to_a
      end
    end
  end
end
