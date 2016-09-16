# TODO: we could get rid of the syntax for multiple expressions with do(expr1, expr2, expr3)
# where `do` just evaluates each arg in the context of the caller, and returns the last one

# TODO: Disallow multiple expressions, it fks w/ the callstack
require 'biolangual'

RSpec.describe 'Interpreting Biolangual' do
  def interpreter
    @interpreter ||= Biolangual::Interpreter.new
  end

  def parse(code)
    Biolangual.parse(code)
  end

  def run(code)
    interpreter.evaluate parse(code)
  end

  # TODO: Make a failing test that says to read the names of the tests before trying to pass them
  describe 'interpreter state is a hash with:' do
    describe 'key: callstack' do
      it 'is an array of stack frames'
      describe 'stack frame is a hash with:' do
        it 'key: ast      the code being evaluated'
        it 'key: index    the index it is located at within the ast'
        it 'key: context  the object the ast is being run on'
        it 'key: return   the result of the most recent evaluated code'
      end
    end
    %w[nil true false main StringPrototype NumberPrototype ListPrototype FunctionPrototype].each do |obj|
      specify "key: #{obj}"
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


  describe 'Interpreter#iterate_evaluation' do
    it 'evaluates the topmost stack frame'
    context 'evaluating when the index is not past the end of the ast' do
      context 'when ast type is expressions' do
        it 'pushes a new stack frame onto the stack with ast: current expression, index: 0, context: current frame\'s context, return: nil'
        it 'does not increment the index'
      end
      context 'when ast type is expression' do
        it 'pushes a new stack frame onto the stack with ast: current message, index: 0, context: current return, return: nil'
        it 'does not increment the index'
      end
      context 'when ast type is number' do
        it 'pops the frame off the stack'
        it 'increments the index'
        it 'sets the biolingual representation of the number into the return key'
      end
      context 'when ast type is string' do
        it 'sets the biolingual representation of the string into the return key'
        it 'increments the index'
      end
    end
    context 'when the index is past the end of the ast' do
      it 'removes the topmost stack frame'
      it 'sets return in the new top to return from the old top'
      it 'increments the index in the new top'
    end
      context 'when ast type is expression' do
        context 'when the frame\'s return object is an AstFunction' do
          it 'puts a new stack frame onto the stack with index: 0, context: the stack frame\'s return, return: nil'
          it 'sets the new stack frame\'s ast to a prototype of the function'
          it 'looks up the message on the frame\'s return object'
        end
        context 'when the frame\'s return object is an BuiltinFunction' do
        context 'when the frame\'s return object is not a function' do
          it 'calls the object with the interpreter state, receiver: frame\'s return, sender: frame\'s context, message: the message\'s name, arguments: the message\'s arguments'
          it 'sets the response object into the frame\'s return key'
          it 'increments the index'
        end
      end
19:        {type: :expression, messages: [first.to_ast, *rest_asts]}
51:        {type: :message, name: '()', arguments: paren_args.to_ast}
67:        {type: :message, name: text_value, arguments: []}
  end

  describe 'Interpreter#eval' do
    it 'adds a stack frame for context: main, ast: the ast, return: nil, and index: 0'
    it 'calls iterate_evaluation until the index is outside the ast'
    it 'returns the return object'
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
