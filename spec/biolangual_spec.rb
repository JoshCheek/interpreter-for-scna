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
      has_important_object :nil,               'bioNil'
      has_important_object :true,              'bioTrue'
      has_important_object :false,             'bioFalse'
      has_important_object :main,              'bioMain'
      has_important_object :StringPrototype,   'StringPrototype'
      has_important_object :NumberPrototype,   'NumberPrototype'
      has_important_object :ListPrototype,     'ListPrototype'
      has_important_object :FunctionPrototype, 'FunctionPrototype'
    end

    describe 'key: callstack' do
      let(:callstack) { interpreter.state[:callstack] }

      it 'is an array of stack frames' do
        expect(callstack).to be_a_kind_of Array
      end

      describe 'stack frame is a hash with:' do
        let(:ast) { parse '1' }
        before { interpreter.begin_evaluation ast }
        it 'key: ast      the code being evaluated' do
          expect(callstack[0][:ast]).to eq ast
        end
        it 'key: index    the index it is located at within the ast' do
          expect(callstack[0][:index]).to eq 0
        end
        it 'key: context  the object the ast is being run on' do
          expect(callstack[0][:context]).to eq interpreter.state[:main]
        end
        it 'key: response the result of the most recent evaluated code' do
          expect(callstack[0][:response]).to eq interpreter.state[:nil]
        end
      end
    end
  end

  describe 'Prototype, the root of all objects' do
    it 'has no prototype because it is the root'
    it 'has the superset of responses, which maps a message to its response'
    it 'can take a string to give it meaning when you look at it in the host language'
  end

  describe 'Prototype.clone' do
    it 'creates a new object and sets its prototype to object'
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
end

__END__

  describe 'Interpreter#iterate_evaluation' do
    it 'evaluates the topmost stack frame'
    context 'evaluating when the index is not past the end of the ast' do
      context 'when ast type is expressions' do
        it 'pushes a new stack frame onto the stack with ast: current expression, index: 0, context: current frame\'s context, response: nil'
        it 'does not increment the index'
      end
      context 'when ast type is expression' do
        it 'pushes a new stack frame onto the stack with ast: current message, index: 0, context: current response, response: nil'
        it 'does not increment the index'
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
    end
    context 'when the index is past the end of the ast' do
      it 'removes the topmost stack frame'
      it 'sets response in the new top to response from the old top'
      it 'increments the index in the new top'
    end
      context 'when ast type is expression' do
        context 'when the frame\'s response object is an AstFunction' do
          it 'puts a new stack frame onto the stack with index: 0, context: the stack frame\'s response, response: nil'
          it 'sets the new stack frame\'s ast to a prototype of the function'
          it 'looks up the message on the frame\'s response object'
        end
        context 'when the frame\'s response object is an BuiltinFunction' do
        context 'when the frame\'s response object is not a function' do
          it 'calls the object with the interpreter state, receiver: frame\'s response, sender: frame\'s context, message: the message\'s name, arguments: the message\'s arguments'
          it 'sets the response object into the frame\'s response key'
          it 'increments the index'
        end
      end
19:        {type: :expression, messages: [first.to_ast, *rest_asts]}
51:        {type: :message, name: '()', arguments: paren_args.to_ast}
67:        {type: :message, name: text_value, arguments: []}
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
