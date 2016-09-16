require 'biolangual/parser'

class Biolangual
  Error = Class.new RuntimeError

  attr_accessor :stdout, :argv, :exit_status, :state

  def initialize(stdout:, argv:)
    self.stdout      = stdout
    self.argv        = argv
    self.exit_status = 0
    self.state       = initial_state
    init_objects
  end

  def stack
    state.fetch :stack
  end

  def current_obj
    stack.last.fetch :object
  end

  def current_response
    stack.last.fetch :response
  end

  def evaluate(ast)
    case ast.fetch :type
    when :number
      require "pry"
      binding.pry
    when :string
      require "pry"
      binding.pry
    when :expression
      messages = ast[:messages]
      if messages.empty?
        bio_nil
      else
        messages.each do |message|
          stack.push object: current_obj, response: bio_nil
          response = evaluate message
          pop response
        end
      end
    when :message
      sender    = current_obj
      receiver  = current_response

      name      = ast.fetch(:name)
      arguments = ast.fetch(:arguments)
      response  = current_obj.lookup(name)
      if response.kind_of? Proc
        stack.push
        response.call(
          this:      receiver,
          that:      sender,
          arguments: arguments,
        )
      else
        response
      end

      case response
      when NativeFunction
      when AstFunction
        require "pry"
        binding.pry
        response.call(
          this:      receiver,
          that:      sender,
          arguments: arguments[:arguments],
        )
      else
        push object: receiver, response: bio_nil
        pop response
      end
    when :expressions
      expressions = ast[:expressions]
      if expressions.empty?
        bio_nil
      else
        expressions.each do |expr|
          stack.push object: current_obj, response: bio_nil
          response = evaluate expr
          pop response
        end
      end
    else raise "wat: #{ast.inspect}"
    end

    #   context 'when the looked up value is a NativeFunction' do
    #     # idk, they need some way to talk back and forth
    #     # [:continue,
    #     # describe 'it calls the NativeFunction with' do
    #     #   specify 'key: that, set to the parent frame\'s context'
    #     #   specify 'key: arguments, set to the ast\'s arguments'
    #     #   specify 'key: interpreter,
    #     # end
    #   end
    # end
  end

  def root_proto
    state.fetch :RootPrototype
  end

  def native_fn_proto
    state.fetch :NativeFunction
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
    attr_accessor :prototype, :responses, :name, :interpreter
    def initialize(prototype:, name: nil, responses: {}, interpreter: nil)
      self.prototype   = prototype
      self.responses   = responses
      self.name        = name
      self.interpreter = interpreter
    end
    def with_name(name)
      self.name = name
      self
    end
    def to_s
      name || super
    end
    def inspect
      name || "{bioObj with responses for: #{responses.keys.join ', '}}"
    end
    def lookup(message, receiver=self)
      response = responses[message]
      return response if response
      return prototype.lookup(message, receiver) if prototype
      raise "#{receiver.inspect} doesn\'t respond to #{message.inspect}"
    end
    def set(key, value)
      responses[key] = value
      value
    end
    def native_method(name, &body)
      set name, NativeFunction.new(name: name, body: body, prototype: interpreter.native_fn_proto)
    end
    def interpreter
      @interpreter || prototype.interpreter
    end
  end

  class NativeFunction < PrototypicalObject
    attr_accessor :body
    def initialize(body:, **keyrest)
      self.body = body
      super **keyrest
    end
    def to_s
      "[fn:#{super}]"
    end
    alias inspect to_s
    def call(this:, that:, arguments:)
      body.call(this: this, that: that, arguments: arguments)
    end
  end

  def initial_state
    rootPrototype     = PrototypicalObject.new(name: 'RootPrototype', prototype: nil, interpreter: self)
    nativeFnPrototype = NativeFunction.new(name: 'NativeFunction', body: :should_not_get_here,  prototype: rootPrototype)
    stringPrototype   = rootPrototype.clone.with_name('StringPrototype')
    numberPrototype   = rootPrototype.clone.with_name('NumberPrototype')
    listPrototype     = rootPrototype.clone.with_name('ListPrototype')
    functionPrototype = rootPrototype.clone.with_name('FunctionPrototype')
    bioNil            = rootPrototype.clone.with_name('bioNil')
    bioTrue           = rootPrototype.clone.with_name('bioTrue')
    bioFalse          = rootPrototype.clone.with_name('bioFalse')
    bioMain           = rootPrototype.clone.with_name('bioMain')

    { nil:               bioNil,
      true:              bioTrue,
      false:             bioFalse,
      main:              bioMain,
      StringPrototype:   stringPrototype,
      NumberPrototype:   numberPrototype,
      ListPrototype:     listPrototype,
      FunctionPrototype: functionPrototype,
      RootPrototype:     rootPrototype,
      NativeFunction:    nativeFnPrototype,
      stack:             [{
        object:   bioMain,
        response: bioNil,
      }],
    }
  end

  def init_objects
    root_proto.native_method('<-') do |this:, that:, arguments:|
      name = arguments[0][:name]
      p name
      this[name] = that.eval(arguments[1])
    end
  end
end
