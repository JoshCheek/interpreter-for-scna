require 'treetop'  # => true

Treetop.load_from_string <<-GRAMMAR  # => AParser
grammar JoshLangParser
  rule program
    expression
  end

  rule expression
    number / string / parentheses / message
  end

  rule number
    [0-9]+ ("." [0-9]+)? {
      def to_ast
        {type: :number, value: text_value.to_f}
      end
    }
  end

  rule string
    '"' [^"]* '"' {
      def to_ast
        {type: :string, value: text_value[1...-1]}
      end
    }
  end

  rule parentheses
    '(' whitespace paren_args whitespace ')' {
      def to_ast
        { type: :message,
          name: '()',
          arguments: paren_args.to_ast
        }
      end
    }
  end

  rule paren_args
    first:(expression?) rest:(whitespace "," whitespace expression)* {
      def to_ast
        if first.empty?
          []
        else
          rest_asts = rest.elements.map { |ast|
            ast.expression.to_ast
          }
          [first.to_ast, *rest_asts]
        end
      end
    }
  end

  rule message
    [^ ]+ {
      def to_ast
        {type: :message, name: text_value, arguments: []}
      end
    }
  end

  rule whitespace
    " "*
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
