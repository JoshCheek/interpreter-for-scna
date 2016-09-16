require 'treetop'

class Biolangual
  filename = File.expand_path 'parser.treetop', __dir__
  compiler = Treetop::Compiler::GrammarCompiler.new
  Parser   = Module.new.module_eval(
    compiler.ruby_source(filename),
    "#{filename}(compiled to ruby)",
  )

  def self.parse(code)
    raise ArgumentError, "#{code.inspect} is not a string" unless code.respond_to? :to_str
    parser     = Parser.new
    parse_tree = parser.parse(code.to_str)
    if parse_tree
      parse_tree.to_ast
    else
      raise "Parsing failed: #{{
        line:   parser.failure_line,
        column: parser.failure_column,
        reason: parser.failure_reason,
      }.inspect}"
    end
  end
end
