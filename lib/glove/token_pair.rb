module Glove
  # Holds a token string and its neighbors in an array
  class TokenPair
    # @!attribute [r] token
    #   @return [String] The word/token
    # @!attribute [r] neighbors
    #   @return [Array<(String)>>] List of neighboring words
    attr_accessor :token, :neighbors

    # Get class instance and set token and neighbors variables
    def initialize(token='', neighbors=[])
      @token, @neighbors = token, neighbors
    end
  end
end
