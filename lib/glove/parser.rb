module Glove
  # Takes a string of text and tokenizes it for usage in {Glove::Corpus}
  #
  class Parser
    DEFAULTS = {
      stem:       true,
      min_length: 3,
      max_length: 25
    }

    # @!attribute [r] text
    #   @return [String] the current value of the text attribute
    #
    attr_reader :text

    # Create a new {Glove::Parser}, passing the text and options as arguments
    #
    # @param [String] text value for the text attribute
    # @param [Hash] options the options to initialize the instance with.
    # @option options [Boolean] :stem Whether to stem the tokens
    # @option options [Integer] :min_length the min allowed length of a word
    # @option options [Integer] :max_length the max allowed length of a word
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
      alphabetic
      split
      stem
      normalize
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
      text.map!(&:stem) if @opt[:stem]
    end

    # Selects words with length within the :min_length and :max_length boundaries
    def normalize
      text.keep_if do |word|
        word.length.between?(@opt[:min_length], @opt[:max_length])
      end
    end
  end
end
