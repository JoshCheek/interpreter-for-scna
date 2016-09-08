require 'treetop'  # => true

Treetop.load_from_string <<-GRAMMAR  # => AParser
grammar JoshLangParser
  rule program
    number
  end

  rule number
    [0-9]+ ("." [0-9]+)? {
      def to_ast
        {type: :number, value: text_value.to_f}
      end
    }
  end
end
GRAMMAR

module JoshLang
  Parser = JoshLangParserParser

  def self.parse(code)
    parse_tree = JoshLangParserParser.new.parse(code)
    parse_tree.to_ast
  end
end
