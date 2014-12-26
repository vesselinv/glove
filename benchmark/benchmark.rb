require 'glove'
require 'benchmark'

bm_dir = File.expand_path File.dirname(__FILE__)
data_path = File.join(bm_dir, 'data')

Benchmark.bm(10) do |bm|
  opt = {stem: false, stop_words: false, normalize: false, alphabetic: false}
  model = Glove::Model.new

  filepath = File.join(data_path, 'quantum-physics.txt')
  text = File.read(filepath)

  bm.report("Fit Text") do
    model.send :fit_corpus, text
  end

  puts "Vocabulary size: #{model.token_pairs.size}"
  puts "Unique tokens: #{model.token_index.size}"

  bm.report("Co-occur") do
    model.send :build_cooc_matrix
    model.send :build_word_vectors
  end

  bm.report("Train") do
    model.train
  end

  bm.report("Similarity") do
    puts "Give me the 3 most similar words to quantum\n"
    puts model.most_similar('quantum').inspect
  end

  bm.report("Analogy") do
    puts "What 3 words relate to atom like quantum relates to mechanics?\n"
    puts model.analogy_words('quantum', 'mechanics', 'atom').inspect
  end
end
