module Glove
  module Workers
    # Performs the traing process on the word vector matrix, as well as word biases
    class TrainingWorker
      extend ::Forwardable

      # @!attribute [r] indices
      #   @return [Glove::Corpus] Shuffled co-occurrence matrix slots
      # @!attribute [r] word_vec
      #   @return [GSL::Matrix] Clone of @parent.word_vec
      # @!attribute [r] word_biases
      #   @return [GSL::Vector] Clone of @parent.word_biases
      attr_accessor :indices, :word_vec, :word_biases

      def_delegators :@parent, :cooc_matrix, :threads, :max_count, :alpha, :learning_rate

      # Create a {Glove::Workers::TrainingWorker} instance
      # @param [Glove::Model] parent Caller class
      # @param [Array<(Integer, Integer)>] indices Shuffled indices of non-zero elements
      #   in the model's co-occurence matrix
      def initialize(parent, indices)
        @parent, @indices = parent, indices
        @word_vec     = @parent.word_vec.dup
        @word_biases  = @parent.word_biases.dup
      end

      # Runs the calculations
      # @return [GSL::Matrix, GSL::Vector] Weighted word vectors and word biases
      def run
        mutex = Mutex.new
        slice_size = indices.size / threads

        workers = indices.each_slice(slice_size).map do |slice|
          Thread.new{ work(slice, mutex) }
        end
        workers.each(&:join)

        [word_vec, word_biases]
      end

      # Perform a full train iteration on the word vectors and word biases
      # @param [Array] slice Shuffled co-occurrence matrix slots
      # @param [Mutex] mutex Thread-safe lock on #apply_weights
      def work(slice, mutex)
        slice.each do |slot|
          w1, w2 = slot
          loss, word_a_norm, word_b_norm = calc_weights(w1, w2)

          mutex.synchronize do
            apply_weights(w1, w2, loss, word_a_norm, word_b_norm)
          end
        end
      end

      # Calculates loss, and norms for word1 (row) and word2 (column) by given
      # indices
      #
      # @param [Integer] w1 Row index
      # @param [Integer] w2 Column index
      # @param [Float] prediction (0.0) Initial predication value
      # @param [Float] word_a_norm (0.0) Initial norm of word at row w1
      # @param [Float] word_b_norm (0.0) Initial norm of word at col w2
      # @return [Float, Float, Float] Array of loss, word_a_norm, word_b_norm
      def calc_weights(w1, w2, prediction=0.0, word_a_norm=0.0, word_b_norm = 0.0)
        count = cooc_matrix[w1, w2]

        word_vec.each_col do |col|
          w1_context = col[w1]
          w2_context = col[w2]

          prediction = prediction + w1_context + w2_context
          word_a_norm += w1_context * w1_context
          word_b_norm += w2_context * w2_context
        end

        prediction = prediction + word_biases[w1] + word_biases[w2]
        word_a_norm = Math.sqrt(word_a_norm)
        word_b_norm = Math.sqrt(word_b_norm)
        entry_weight = [1.0, (count/max_count)].min ** alpha
        loss = entry_weight * (prediction - Math.log(count))

        [loss, word_a_norm, word_b_norm]
      end

      # Applies calculated weights to @word_vec and @word_biases. MUST be called
      # in a Mutex#synchronize block
      #
      # @param [Integer] w1 Row index
      # @param [Integer] w2 Column index
      # @param [Float] loss Loss value
      # @param [Float] word_a_norm Norm of word at row w1
      # @param [Float] word_b_norm Norm of word at col w2
      def apply_weights(w1, w2, loss, word_a_norm, word_b_norm)
        word_vec.each_col do |col|
          col[w1] = (col[w1] - learning_rate * loss * col[w2]) / word_a_norm
          col[w2] = (col[w2] - learning_rate * loss * col[w2]) / word_b_norm
        end

        word_biases[w1] -= learning_rate * loss
        word_biases[w2] -= learning_rate * loss
      end
    end
  end
end
