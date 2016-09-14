require 'treetop'

module Biolangual
  filename = File.expand_path 'parser.treetop', __dir__
  compiler = Treetop::Compiler::GrammarCompiler.new
  Parser   = Module.new.module_eval(
    compiler.ruby_source(filename),
    "#{filename}(compiled to ruby)",
  )

  def self.parse(code)
    raise ArgumentError, "#{code.inspect} is not a string" unless code.respond_to? :to_str
    parse_tree = Parser.new.parse(code.to_str)
    parse_tree.to_ast
  end
end
