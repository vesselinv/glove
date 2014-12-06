require 'glove'
require 'ruby-prof'

bm_dir = File.expand_path File.dirname(__FILE__)
data_path = File.join(bm_dir, 'data')
output_dir = File.join(bm_dir, 'results')

result = RubyProf.profile do
  model = Glove::Model.new

  filepath = File.join(data_path, 'quantum-physics.txt')
  text = File.read(filepath)

  model.fit(text)
  model.train
end

printer = RubyProf::MultiPrinter.new(result)
printer.print(path: "#{output_dir}", profile: 'multi', application: 'glove')
