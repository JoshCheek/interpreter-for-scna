require 'open3'
require 'biolangual'

RSpec.describe 'acceptance test: examples/word_count' do
  let(:program_path) { File.expand_path '../examples/word_count.bio', __dir__ }
  let(:biolang_path) { File.expand_path '../bin/bio', __dir__ }

  # let(:program_path) { File.expand_path '../examples/word_count.rb', __dir__ }
  # let(:biolang_path) { '/Users/josh/.rubies/ruby-2.2.2/bin/ruby' }

  def run(argv)
    Open3.capture3(biolang_path, program_path, *argv)
  end

  it 'can parse the example program' do
    program = File.read(program_path)
    ast = Biolangual.parse(program)
    expect(ast[:type]).to eq :expression
  end

  it 'prints an error when there is only one arg' do
    stdout, stderr, status = run([])
    expect(stderr).to eq ""
    expect(stdout).to eq "You must provide an argument to count\n"
    expect(status.exitstatus).to eq 1
  end

  it 'counts and prints the sorted words and counts' do
    stdout, stderr, status = run(['the cat and the hat'])
    expect(stderr).to eq ""
    expect(stdout).to eq "5\n"
    expect(status.exitstatus).to eq 0
  end
end
