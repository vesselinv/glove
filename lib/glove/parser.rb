module Glove
  # Takes a string of text and tokenizes it for usage in {Glove::Corpus}
  #
  class Parser
    # Default options (see #initialize)
    DEFAULTS = {
      stem:       true,
      min_length: 3,
      max_length: 25,
      alphabetic: true,
      normalize:  true,
      stop_words: true
    }

    # @!attribute [r] text
    #   @return [String] the current value of the text attribute
    #
    attr_reader :text

    # Create a new {Glove::Parser}, passing the text and options as arguments
    #
    # @param [String] text value for the text attribute
    # @param [Hash] options the options to initialize the instance with.
    # @option options [Boolean] :stem (true) Whether to stem the tokens
    # @option options [Boolean] :alphabetic (true) Remove any non-alphabetic chars
    # @option options [Boolean] :normalize (true) Normalize the text and keep
    #   words with length between option[:min_length] and option[:max_length]
    # @option options [Boolean] :stop_words (true) Filter stop words
    # @option options [Integer] :min_length (3) the min allowed length of a word
    # @option options [Integer] :max_length (25) the max allowed length of a word
    # @return [Glove::Parser] A new parser.
    def initialize(text, options={})
      @text, @opt = text, DEFAULTS.dup.merge(options)
    end

    # Call all parsing methods in the class and return the final text value as
    # array of words
    #
    # @return [Array] The tokens array
    def tokenize
      downcase
      stop_words  if @opt[:stop_words]
      alphabetic  if @opt[:alphabetic]
      split
      normalize   if @opt[:normalize]
      stem        if @opt[:stem]
      text
    end

    # Downcases the text value
    def downcase
      text.downcase!
    end

    # Splits the text string into an array of words
    def split
      @text = text.split
    end

    # Filters out the text leaving only alphabetical characters in words
    # and splits the words
    def alphabetic
      text.gsub!(/([^[:alpha:]]+)|((?=\w*[a-z])(?=\w*[0-9])\w+)/, ' ')
    end

    # Stems every member of the text array
    def stem
      text.map!(&:stem)
    end

    # Selects words with length within the :min_length and :max_length boundaries
    def normalize
      text.keep_if do |word|
        word.length.between?(@opt[:min_length], @opt[:max_length])
      end
    end

    # Exclude words that are in the STOP_WORDS array
    def stop_words
      @text = text.scan(/(\w+)(\W+)/).reject do |(word, other)|
        stop_words_array.include? word
      end.flatten.join
    end

    # Reads the default stop words file and return array of its entries
    def stop_words_array
      @stop_words ||= File.read(File.join(Glove.root_path, 'resources', 'en.stop')).split
    end
  end
end
