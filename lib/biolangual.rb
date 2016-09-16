require 'biolangual/parser'

class Biolangual
  Error = Class.new RuntimeError

  attr_accessor :stdout, :argv, :exit_status, :state

  def initialize(stdout:, argv:)
    self.stdout      = stdout
    self.argv        = argv
    self.exit_status = 0
    self.state       = initial_state
  end

  def evaluate(ast)
  end

  def begin_evaluation(ast)
    state[:callstack].push({
      ast:      ast,
      index:    0,
      context:  state[:main],
      response: state[:nil],
    })
  end


  class Named
    def initialize(name)
      @name = name
    end
    def to_s
      @name
    end
  end

  def initial_state
    bionil            = Named.new('bioNil')
    bioTrue           = Named.new('bioTrue')
    bioFalse          = Named.new('bioFalse')
    bioMain           = Named.new('bioMain')
    stringPrototype   = Named.new('StringPrototype')
    numberPrototype   = Named.new('NumberPrototype')
    listPrototype     = Named.new('ListPrototype')
    functionPrototype = Named.new('FunctionPrototype')

    { nil:               bionil,
      true:              bioTrue,
      false:             bioFalse,
      main:              bioMain,
      StringPrototype:   stringPrototype,
      NumberPrototype:   numberPrototype,
      ListPrototype:     listPrototype,
      FunctionPrototype: functionPrototype,
      callstack:         [],
    }
  end
end
