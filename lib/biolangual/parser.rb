require 'treetop'

module Biolangual
  filename = File.expand_path 'parser.treetop', __dir__
  compiler = Treetop::Compiler::GrammarCompiler.new
  Parser   = Module.new.module_eval(
    compiler.ruby_source(filename),
    "#{filename}(compiled to ruby)",
  )

  def self.parse(code)
    parse_tree = Parser.new.parse(code)
    parse_tree.to_ast
  end
end
