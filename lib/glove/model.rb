module Glove
  class Model
    # Default options
    DEFAULTS = {
      max_count:      100,
      learning_rate:  0.05,
      alpha:          0.75,
      num_components: 30,
      epochs:         5,
      threads:        2
    }

    # @!attribute [r] corpus
    #   @return [Glove::Corpus] reference to the Corpus instance
    # @!attribute [r] token_index
    #   @return [Hash] reference to corpus.index
    # @!attribute [r] token_pairs
    #   @return [Array<(Glove::TokenPair)>] reference to corpus.pairs
    # @!attribute [rw] word_vec
    #   @return [GSL::Matrix] the word vector matrix
    # @!attribute [rw] word_biases
    #   @return [GSL::Vector] the vector holding the word biases
    attr_reader :opts, :window, :epochs, :num_components, :min_count, :learning_rate, :alpha, :max_count, :threads, :cooc_matrix, :corpus, :token_index, :token_pairs
    attr_accessor :word_vec, :word_biases

    # Create a new {Glove::Model} instance. Accepts options for
    # {Glove::Corpus} and {Glove::Parser} which only get forwarded
    # and not used in this class.
    #
    # @param [Hash] options the options to initialize the instance with.
    # @option options [Integer] :max_count (100) Parameter specifying cutoff in
    #   weighting function
    # @option options [Float] :learning_rate (0.05) Initial learning rate
    # @option options [Float] :alpha (0.75) Parameter in exponent of weighting
    #   function
    # @option options [Integer] :num_components (30) Column size of the word vector
    #   matrix
    # @option options [Integer] :epochs (5) Number of training iterations
    # @option options [Integer] :threads (2) Number of threads to use in building
    #   the co-occurence matrix and training iterations
    # @return [Glove::Model] A GloVe model.
    def initialize(options={})
      @opts = DEFAULTS.dup.merge(options)
      @opts.each do |key, value|
        instance_variable_set :"@#{key}", value
      end

      @cooc_matrix = nil
      @word_vec    = nil
      @word_biases = nil
    end

    # Fit a string or {Glove::Corpus} instance and build co-occurance matrix
    #
    # @param [String, Glove::Corpus] text The text to train from
    # @example Provide corpus for the model
    #   model = Glove::Model.new
    #   model.fit(File.read('shakespeare.txt'))
    # @example Provide a {Glove::Corpus} instance as text argument
    #   model = Glove::Model.new
    #   corpus = Glove::Corpus.build(File.read('shakespeare.txt'))
    #   model.fit(corpus)
    # @return [Glove::Model] Current instance
    def fit(text)
      @corpus =
        if text.is_a? Corpus
          text
        else
          Corpus.build(text, opts)
        end

      @token_index = corpus.index
      @token_pairs = corpus.pairs

      build_cooc_matrix
      self
    end

    # Train the model. Must call #fit prior
    # @return [Glove::Model] Current instance
    def train
      cols            = token_index.size
      @word_vec       = GSL::Matrix.rand(cols, num_components)
      @word_biases    = GSL::Vector.alloc(cols)
      shuffle_indices = matrix_nnz
      slice_size      = shuffle_indices.size / threads

      (0..epochs).each do |epoch|
        shuffled = shuffle_indices.shuffle
        mutex = Mutex.new

        # Split up the indices and assign them to a thread to avoid race conditions
        workers = shuffled.each_slice(slice_size).map do |slice|
          Thread.new{ epoch_thread(slice, mutex) }
        end
        workers.each(&:join)
      end

      self
    end

    # @todo save vectors and matrices to files. Save token index and pairs as
    # well and then accept them as argument in #load??
    def save(cooc_file, vec_file, bias_file)
      cooc_matrix.fwrite(cooc_file)
      word_vec.fwrite(vec_file)
      word_biases.fwrite(bias_file)
    end

    # @todo load vectors and matrices from files. Best to provide the text file
    # path as well so that the token index and pairs can be reconstructed and
    # hence the matrix sizes determined.
    def load
      raise "Not implemented"
    end

    # @todo create graph of the word vector matrix
    def vizualize
      raise "Not implemented"
    end

    # Get a words that relates to :target like :word1 relates to :word2
    #
    # @param [String] word1
    # @param [String] word2
    # @param [Integer] num Number of related words to :target
    # @param [Float] accuracy Allowance in difference of target cosine
    #   and related word cosine distances
    # @example What words relate to atom like quantum relates to physics?
    #   model.analogy_words('quantum', 'physics', 'atom') # => {"electron"=>0.9858380292886947, "energi"=>0.9815122410243475, "photon"=>0.9665073849076669}
    # @return [Hash{String=>Float}] List of related words to target
    def analogy_words(word1, word2, target, num = 3, accuracy = 0.0001)
      word1  = word1.stem
      word2  = word1.stem
      target = target.stem

      distance = cosine(transform(word1), transform(word2))

      vector_distance(target).reject do |item|
        dist = item[1]
        diff = dist.to_f.abs - distance
        diff.abs < accuracy
      end.take(num).to_h
    end

    # Get most similar words to :word
    #
    # @param [String] word The word to find similar to
    # @param [Integer] num (3) Number of similar words to :word
    # @example Get 1 most similar word to 'physics'
    #   model.most_similar('physics', 1) # => {"quantum"=>0.9967993356234444}
    # @return [Hash{String=>Float}] List of most similar words with cosine
    #   distance as values
    def most_similar(word, num=3)
      word = word.stem

      vector_distance(word).take(num).to_h
    end

    # Prevent token_pairs, matrices and vectors to fill up the terminal
    def inspect
      to_s
    end

    private

    # Perform a train iteration
    def epoch_thread(shuffled, mutex)
      shuffled.each do |j|
        w1, w2 = j
        count = cooc_matrix[w1, w2]

        prediction  = 0.0
        word_a_norm = 0.0
        word_b_norm = 0.0

        word_vec.each_col do |col|
          w1_context = col[w1]
          w2_context = col[w2]

          prediction = prediction + w1_context + w2_context
          word_a_norm += w1_context * w1_context
          word_b_norm += w2_context * w2_context
        end

        prediction = prediction + word_biases[w1] + word_biases[w2]
        word_a_norm = Math.sqrt(word_a_norm)
        word_b_norm = Math.sqrt(word_a_norm)
        entry_weight = [1.0, (count/max_count)].min ** alpha
        loss = entry_weight * (prediction - Math.log(count))

        mutex.synchronize do
          word_vec.each_col do |col|
            col[w1] = (col[w1] - learning_rate * loss * col[w2]) / word_a_norm
            col[w2] = (col[w2] - learning_rate * loss * col[w2]) / word_b_norm
          end

          word_biases[w1] -= learning_rate * loss
          word_biases[w2] -= learning_rate * loss
        end
      end
    end

    # Build the co-occurence matrix
    def build_cooc_matrix
      size = token_index.size
      slice_size = size / threads

      @cooc_matrix = GSL::Matrix.alloc(size, size)
      mutex = Mutex.new

      workers = token_index.each_slice(slice_size).map do |slice|
        Thread.new{ matrix_thread(slice, mutex) }
      end
      workers.each(&:join)
    end

    # Sum up the word-word co-ocurence count for a segment of the tokens,
    # creates a word vector and set the corresponding cooc_maxtrix column values
    def matrix_thread(token_slice, mutex)
      token_slice.to_h.each do |token, index|
        vector = GSL::Vector.alloc(token_index.size)

        token_pairs.each do |pair|
          key = token_index[pair.token]
          sum = pair.neighbors.select{ |word| word == token }.size
          vector[key] += sum
        end

        mutex.synchronize do
          cooc_matrix.set_col(index, vector)
        end
      end
    end

    # Array of all non-zero (both row and col) value coordinates in the
    # cooc_matrix
    def matrix_nnz
      entries = []
      cooc_matrix.enum_for(:each_col).each_with_index do |col, col_idx|
        col.enum_for(:each).each_with_index do |row, row_idx|
          value = cooc_matrix[row_idx, col_idx]

          entries << [row_idx, col_idx] unless value.zero?
        end
      end
      entries
    end

    # Find the vector values for a given word
    #
    # @param [String] word The word to transform into a vector
    # @return [GSL::Vector] The corresponding vector into the #word_vec matrix
    def transform(word)
      word_index = token_index[word]

      return nil unless word_index
      word_vec[word_index, nil]
    end

    def vector_distance(word)
      vector = transform(word)

      token_index.map.with_index do |(token,count), idx|
        next if token.eql? word
        [token, cosine(vector, word_vec[idx, nil])]
      end.compact.sort{ |a,b| b[1] <=> a[1] }
    end

    # Compute cosine distance between two vectors
    #
    # @param [GSL::Vector] vector1 First vector
    # @param [GSL::Vector] vector2 Second vector
    # @return [Float] the cosine distance
    def cosine(vector1, vector2)
      return 0 if vector1.nil? || vector2.nil?
      vector1.dot(vector2) / (vector1.norm * vector2.norm)
    end
  end
end
