require 'benchmark'
require 'glove'

class CoOccurrence
  def initialize(corpus)
    @token_count = corpus.count
    @token_index = corpus.index
    @token_pairs = corpus.pairs
    @matrix = nil
  end

  def without_threads
    vectors = @token_index.map do |token, index|
      build_cooc_matrix_col([token, index])
    end

    @matrix = GSL::Matrix.alloc(*vectors)
  end

  def with_threads
    @matrix = GSL::Matrix.alloc(@token_index.size, @token_index.size)
    mutex = Mutex.new

    workers = @token_index.each_slice(4).map do |slices|
      Thread.new{ work(slices, mutex) }
    end
    workers.each(&:join)
  end

  def with_processes
    vectors = Parallel.map(@token_index, in_processes: 4) do |slice|
      build_cooc_matrix_col(slice)
    end

    @matrix = GSL::Matrix.alloc(*vectors)
  end

  def build_cooc_matrix_col(slice)
    token = slice[0]
    vector = GSL::Vector.alloc(@token_index.size)

    @token_pairs.each do |pair|
      key = @token_index[pair.token]
      sum = pair.neighbors.select{ |word| word == token }.size
      vector[key] += sum
    end

    vector.to_a
  end

  def work(slices, mutex)
    slices.each do |slice|
      vector = build_cooc_matrix_col(slice)

      mutex.synchronize do
        @matrix.set_col(slice[1], vector)
      end
    end
  end
end

bm_dir    = File.expand_path File.dirname(__FILE__)
data_path = File.join(bm_dir, 'data')
text_path = File.join(data_path, 'quantum-physics.txt')
text      = File.read(text_path).split.take(10_000).join(' ')
corpus    = Glove::Corpus.build(text, min_count: 2)
coocc     = CoOccurrence.new(corpus)

puts "\nVocabulary size: #{corpus.pairs.size}"
puts "Unique tokens: #{corpus.index.size}\n\n"

Benchmark.bm(10) do |b|

  b.report('No threads') do
    coocc.without_threads
  end

  b.report('With threads') do
    coocc.with_threads
  end

  b.report('With processes') do
    coocc.with_processes
  end
end
