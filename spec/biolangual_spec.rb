require 'biolangual'

RSpec.describe 'Interpreting Biolangual' do
  def interpreter
    @interpreter ||= Biolangual.new stdout: '', argv: []
  end

  def parse(code)
    Biolangual.parse(code)
  end

  def run(code)
    interpreter.evaluate parse(code)
  end

  # TODO: Make a failing test that says to read the names of the tests before trying to pass them
  describe 'interpreter state is a hash with:' do
    describe 'important objects can be accessed directly and have special names to make implementation output clearer' do
      def self.has_important_object(key, string_representation)
        specify "key: #{key} is an important object whose to_s is #{string_representation} (object will be described later)" do
          obj = interpreter.state.fetch key.to_sym
          expect(obj.to_s).to eq string_representation
        end
      end
      has_important_object :RootPrototype,     'RootPrototype'
      has_important_object :StringPrototype,   'StringPrototype'
      has_important_object :NumberPrototype,   'NumberPrototype'
      has_important_object :ListPrototype,     'ListPrototype'
      has_important_object :FunctionPrototype, 'FunctionPrototype'
      has_important_object :nil,               'bioNil'
      has_important_object :true,              'bioTrue'
      has_important_object :false,             'bioFalse'
      has_important_object :main,              'bioMain'
    end

    describe 'key: callstack' do
      let(:callstack) { interpreter.state[:callstack] }

      it 'is an array of stack frames, with one frame by default' do
        expect(callstack).to be_a_kind_of Array
      end

      describe 'stack frame is a hash with:' do
        specify 'key: ast      the code being evaluated' do
          expect(callstack[0]).to have_key :ast
        end
        specify 'key: index    the index it is located at within the ast' do
          expect(callstack[0]).to have_key :index
        end
        specify 'key: context  the object the ast is being run on' do
          expect(callstack[0]).to have_key :context
        end
        specify 'key: response the result of the most recent evaluated code' do
          expect(callstack[0]).to have_key :response
        end
      end

      describe 'the initial stack frame' do
        specify 'the ast is an internal (parser does not emit it) ast of: {type: :idle}' do
          expect(callstack[0][:ast]).to eq({type: :idle})
        end
        specify 'index is 0' do
          expect(callstack[0][:index]).to eq 0
        end
        specify 'context is main' do
          expect(callstack[0][:context]).to eq interpreter.state[:main]
        end
        specify 'response is nil' do
          expect(callstack[0][:response]).to eq interpreter.state[:nil]
        end
      end
    end
  end

  describe 'convenience methods' do
    specify '`root_proto`   returns the RootPrototype' do
      expect(interpreter.root_proto).to equal interpreter.state.fetch(:RootPrototype)
    end
    specify '`string_proto` returns the StringPrototype' do
      expect(interpreter.string_proto).to equal interpreter.state.fetch(:StringPrototype)
    end
    specify '`number_proto` returns the NumberPrototype' do
      expect(interpreter.number_proto).to equal interpreter.state.fetch(:NumberPrototype)
    end
    specify '`list_proto`   returns the ListPrototype' do
      expect(interpreter.list_proto).to equal interpreter.state.fetch(:ListPrototype)
    end
    specify '`fn_proto`     returns the FunctionPrototype' do
      expect(interpreter.fn_proto).to equal interpreter.state.fetch(:FunctionPrototype)
    end
    specify '`bio_nil`      returns bioNil' do
      expect(interpreter.bio_nil).to equal interpreter.state.fetch(:nil)
    end
    specify '`bio_true`     returns bioTrue' do
      expect(interpreter.bio_true).to equal interpreter.state.fetch(:true)
    end
    specify '`bio_false`    returns bioFalse' do
      expect(interpreter.bio_false).to equal interpreter.state.fetch(:false)
    end
    specify '`bio_main`     returns bioMain' do
      expect(interpreter.bio_main).to equal interpreter.state.fetch(:main)
    end
  end

  describe 'Prototype, the root of all objects' do
    let(:proto) { interpreter.state[:RootPrototype] }
    it 'has no prototype because it is the root' do
      expect(proto.prototype).to eq nil
    end
    it 'has a hash of responses, which maps a message to its response' do
      expect(proto.responses).to be_a_kind_of Hash
    end
  end

  describe 'Prototype.clone' do
    it 'creates a new object and sets its prototype to the cloned object'
  end

  describe 'Prototype.lookup' do
    it 'returns the response to the message when there is one in responses'
    it 'finds the message in the prototype chain when there isn\'t a response'
    it 'raises an error if none of the prototypes had a response'
    it 'sets `this` on the object, if it is a function'
  end

  describe 'Prototype.evaluate' do
    it 'sets the receiver to the current object'
    it 'evaluates the ast'
  end

  describe 'Function' do
    it 'is a clone of Prototype'

    describe 'is constructed by Prototype.fn' do
      it 'returns a clone of Function'
      it 'the clone has all arguments except the last set to its argument names'
      it 'the clone has the last argument set to its body'
    end

    describe 'calling' do
      it 'evaluates the body in a clone of the function'
      it 'sets the receiver to `this`'
      it 'sets the sender to `that`'
      it 'sets each of the function\'s argument names to the argument AST'
      it 'evalutes the body in the context of the function call, returning the response of its last line'
    end
  end


  describe 'Interpreter#iterate_evaluation evalutes the topmost stack frame' do
    context 'when ast type is idle' do
      it 'does nothing'
    end
    context 'when ast type is expression and index is not past the last message' do
      it 'pushes a new stack frame onto the stack with ast: current context, index: 0, context: current response, response: bio_nil'
      it 'does not increment the index'
    end
    context 'when ast type is expression and index is past the last message' do
      it 'pops the frame off the stack'
      it 'increments the index'
      it 'sets the response to the popped frame\'s response'
    end
    context 'when ast type is number' do
      it 'pops the frame off the stack'
      it 'increments the index'
      it 'sets the biolingual representation of the number into the response key'
    end
    context 'when ast type is string' do
      it 'sets the biolingual representation of the string into the response key'
      it 'increments the index'
    end
    context 'when the ast type is message and the index is 1' do
      it 'pops the frame off the stack'
      it 'increments the index'
      it 'sets the popped frame\'s response into the response key'
    end

    context 'when the ast type is message, it looks up the message\'s name on context and' do
      context 'when the looked up value is not a function' do
        it 'pops the frame off the stack'
        it 'increments the index'
        it 'sets the looked up value to as the response'
      end

      context 'when the looked up value is a NativeFunction' do
        # idk, they need some way to talk back and forth
        # [:continue,

        # describe 'it calls the NativeFunction with' do
        #   specify 'key: that, set to the parent frame\'s context'
        #   specify 'key: arguments, set to the ast\'s arguments'
        #   specify 'key: interpreter,
        # end
      end
    end
  end

  describe 'Interpreter#eval' do
    it 'adds a stack frame for context: main, ast: the ast, response: nil, and index: 0'
    it 'calls iterate_evaluation until the index is outside the ast'
    it 'returns the response object'
  end

  describe 'Number' do
    it 'is the prototype of literal numbers'
    specify 'have a + message which adds two together'
    specify 'have an == message which compares their equality, returning true or false'
  end

  describe 'String' do
    it 'is the prototype of literal strings'
  end
end

  # Prototype responses:
  #   clone
  #   fn
  #   eval(ast)
  #   true
  #   false
  #   if
  # Function responses:
  #   () calls the function
  # main:
  #   argv
  #   stdout
  # stdout:
  #   write
