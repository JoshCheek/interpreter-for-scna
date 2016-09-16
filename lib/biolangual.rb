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

  def root_proto
    state.fetch :RootPrototype
  end

  def string_proto
    state.fetch :StringPrototype
  end

  def number_proto
    state.fetch :NumberPrototype
  end

  def list_proto
    state.fetch :ListPrototype
  end

  def fn_proto
    state.fetch :FunctionPrototype
  end

  def bio_nil
    state.fetch :nil
  end

  def bio_true
    state.fetch :true
  end

  def bio_false
    state.fetch :false
  end

  def bio_main
    state.fetch :main
  end



  class PrototypicalObject
    attr_accessor :prototype, :responses, :name
    def initialize(prototype:, name: nil, responses: {})
      self.prototype = prototype
      self.responses = responses
      self.name      = name
    end
    def to_s
      name || super
    end
  end

  def initial_state
    rootPrototype     = PrototypicalObject.new(name: 'RootPrototype',     prototype: nil)
    stringPrototype   = PrototypicalObject.new(name: 'StringPrototype',   prototype: rootPrototype)
    numberPrototype   = PrototypicalObject.new(name: 'NumberPrototype',   prototype: rootPrototype)
    listPrototype     = PrototypicalObject.new(name: 'ListPrototype',     prototype: rootPrototype)
    functionPrototype = PrototypicalObject.new(name: 'FunctionPrototype', prototype: rootPrototype)
    bioNil            = PrototypicalObject.new(name: 'bioNil',            prototype: rootPrototype)
    bioTrue           = PrototypicalObject.new(name: 'bioTrue',           prototype: rootPrototype)
    bioFalse          = PrototypicalObject.new(name: 'bioFalse',          prototype: rootPrototype)
    bioMain           = PrototypicalObject.new(name: 'bioMain',           prototype: rootPrototype)

    { nil:               bioNil,
      true:              bioTrue,
      false:             bioFalse,
      main:              bioMain,
      StringPrototype:   stringPrototype,
      NumberPrototype:   numberPrototype,
      ListPrototype:     listPrototype,
      FunctionPrototype: functionPrototype,
      RootPrototype:     rootPrototype,
      callstack:         [{
        ast:      {type: :idle},
        index:    0,
        context:  bioMain,
        response: bioNil,
      }],
    }
  end
end
