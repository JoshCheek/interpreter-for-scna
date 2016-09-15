# From my lisp implementation (https://gist.github.com/JoshCheek/346f8796d057c57ab471f2fe32694ec8),
# this is what I needed to write a basic program:
# Lists:                car cdr cons            | handled by Literals ()
# Logic:                or and if true false    | ?
# Multiple expressions: progression             | ? maybe `do` which evalutes its args in the caller
# side effects:         print_num               | ?
# Numbers:              zero succ pred is_zero  | we have them

# TODO: Is there really value in letting them have multiple prototypes?
# it seems to be fucking up what I want to do (responders like method_missing)
# Ruby's mixins seem much more elegant
#
# TODO: we could get rid of the syntax for multiple expressions with do(expr1, expr2, expr3)
# where `do` just evaluates each arg in the context of the caller, and returns the last one

require 'biolangual'

RSpec.describe 'Interpreting Biolangual' do
  def interpreter
    @interpreter ||= Biolangual::Interpreter.new
  end

  def parse(code)
    Biolangual.parse(code)
  end

  def run(code)
    interpreter.evaluate! parse(code)
   end

  # TODO: Make a failing test that says to read the names of the tests before trying to pass them

  describe 'an object is anything which can be sent a message (passed as an arg to the interpreter\'s `send` method)' do
    describe 'sending a message to an object required' do
      specify '`receiver`  the object getting the message' do
        assert_message_passing receiver: interpreter.number_proto
      end
      specify '`sender`    the object giving the message' do
        assert_message_passing sender: interpreter.number_proto
      end
      specify '`message`   the data passing from the sender to the receiver, always a string for now' do
        assert_message_passing message: interpreter.biostring('true') # a message it should respond to, just returns the object representing true
      end
      specify '`arguments` is a list of objects needed for responding to the message' do
        arg = interpreter.biostring('some_arg')
        assert_message_passing arguments: interpreter.biolist([arg])
      end
    end

    describe 'resulting in an array of `response` or `error`, and associated data' do
      specify 'a `response`\'s data is an object to be given back to the caller' do
        # a message it should respond to, just returns the object representing false
        response = assert_message_passing message: interpreter.biostring('false')
        expect(response[0]).to eq :response
        expect(response[1]).to eq interpreter.false
      end

      specify 'an `error`\'s data is a description of what went wrong (start with a string)' do
        response = assert_message_passing message: interpreter.biostring('some-bs-message')
        expect(response[0]).to eq :error
        expect(response[1]).to eq "Number does not respond to \"some-bs-message\""
      end
    end

    # you'll need to make some objects available to get past this step
    def assert_message_passing(options)
      some_object = interpreter.string_proto

      # build the invocation
      receiver  = options.fetch :receiver,  some_object
      sender    = options.fetch :sender,    some_object
      message   = options.fetch :message,   interpreter.biostring('identity') # a message it should respond to (just returns the receiver)
      arguments = options.fetch :arguments, interpreter.biolist([])

      # invoke
      response = interpreter.call(receiver, sender, message, arguments)

      # verify it saw what we sent
      expect(interpreter.last_message_sent).to eq(
        receiver:  receiver,
        sender:    sender,
        message:   message,
        arguments: arguments,
      )

      # return the response so it can be asserted against, if desired
      response
    end
  end


  describe 'evaluate' do
    it 'takes an ast, evaluates it, returns the result, even if its an error' do
      ast        = Biolangual.parse('some-bs-message')
      type, data = interpreter.evaluate(ast)
      expect(type).to eq :error
      expect(data).to match /some-bs-message/
    end
  end

  describe 'evaluate!' do
    it 'takes an ast, evaluates it, returns the response\'s data' do
      ast  = Biolangual.parse('false')
      data = interpreter.evaluate!(ast)
      expect(data).to eq interpreter.false
    end
    it 'raises an exception if the result is an error' do
      ast = Biolangual.parse('some-bs-message')
      expect { interpreter.evaluate!(ast) }
        .to raise_error Biolangual::Error, /some-bs-message/
    end
  end


  describe 'literals (objects that are created with syntax)' do
    specify 'can be numbers, objects which represent floats' do
      result = run('123.4')
      expect(result.internal_data).to equal 123.4
      expect(result).to eq interpreter.bionum(123.4)
    end
    specify 'can be strings, objects which wrap strings' do
      result = run('"abc"')
      expect(result.internal_data).to eq 'abc'
      expect(result).to eq interpreter.biostring('abc')
    end
  end

  describe 'execution context' do
    specify 'there is always an object, the default object is main' do
      expect(interpreter.current_object).to eq interpreter.main_object
    end

    context 'the current object is always the last evaluted object' do
      specify 'for numbers' do
        run '123'
        expect(interpreter.current_object).to eq interpreter.bionum(123)
      end

      specify 'for strings' do
        run '"abc"'
        expect(interpreter.current_object).to eq interpreter.biostring("abc")
      end

      specify 'for messages' do
        run 'true'
        expect(interpreter.current_object).to eq interpreter.true
      end

      specify 'it does not update the default object when there is an error' do
        type, data = interpreter.evaluate parse('some-bs-message')
        expect(type).to eq :error
        expect(interpreter.current_object).to eq interpreter.main_object
      end
    end
  end


  # TODO: If we allow dynamic responders, we can do away with the literals (123 becomes a message, and is matched by the responder that looks for messages that are number literals)
  # then, we can also get rid of the special case for the first arg! and for evaluating nonmessages
  describe 'expressions' do
    specify 'can begin with a literal, in which case they evalute to that literal' do
      expect(run '123.4').to eq interpreter.bionum(123.4)
    end
    specify 'can begin with a message, in which case it is sent to the current object (responding will be described later)' do
      expect(run 'identity').to equal interpreter.main_object
    end
    specify 'messages after the first are sent to the response of the the expression to their left' do
      expect(run 'true true?').to equal interpreter.true
      expect(run 'false true?').to equal interpreter.false
    end
    specify 'when a message is sent to an object that doesn\'t respond to it it raises an error' do
      type, data = interpreter.evaluate parse 'true lolol'
      expect(type).to eq :error
      expect(data).to match /lolol/
    end
  end

  describe 'All objects are prototypical unless they explicitly specify otherwise' do
    describe 'prototypes must have the following responses' do
      specify '`responses`, returning an associative array with keys being messages and values being responses' do
        result = run('responses').to_ruby
        expect(result).to be_a_kind_of Array
        expect(result.map(&:length).uniq).to eq [2] # key/value pairs
      end
      specify '`prototypes` is a list of other places to look for responses' do
        result = run('prototypes').to_ruby
        expect(result).to be_a_kind_of Array
        expect(result).to be_all { |proto| proto.respond_to? :call }
      end
      xspecify '`<-` is a function that adds a response to the `receiver`' do
        expect { run 'lolol' }.to raise_error Biolangual::Error, /lolol/
        response = run '<-(lolol, 123)'
        # TODO: Uhm, what does this return?
        # expect(response).to ??
        expect(run('lolol').to_ruby).to eq 123.0
      end
      specify '`clone` responds with a new object and sets the receiver as its only prototype'
      specify '`responses` is an associative array of strings and their responses'
      specify '`prototypes` is a list of other places to look for responses'
    end
    describe 'inheritance / message lookup' do
      it 'first looks for the message in the responses'
      it 'then looks for the message in the prototypes, in order'
    end
  end

  describe 'EntryPoints has responses of objects that you may wish to reference by name (except for Comment)' do
    specify 'by convention, these objects all respond to `name` with a string of their name'
    specify 'Comment is special, it doesnot respond with its name'
    describe 'the responses are:' do
      # not sure how bools are going to fall out yet
      %w[EntryPoints String Number Literals Extensible Functional Main List Function].each do |entry_point|
        specify entry_point
      end
    end
    it 'returns an error for all other messages'
  end

  describe 'Comment is a non-prototypical object' do
    it 'responds to no messages (ie its call method will be different from all the other objects)'
    it 'Comment is the name we give it... if it knows anything of its name, it does not tell us, that would disrupt its duty as a comment'
  end

  describe '`()` is the most important message' do
    it 'it is the only message that is able to include a list of arguments' # doesn't explode
    it 'passes its arguments as ASTs' # track the last message sent
  end

  describe 'Literals is an object that gives names to useful objects that are usually keywords' do
    it 'has no prototypes'
    it 'only has the responses `true`, `false`, `nil`, `identity`, `()`, `//`'
    specify '`true`     response: the true object'
    specify '`false`    response: the false object'
    specify '`nil`      response: the nil object'
    specify '`identity` response: a function that responds to calls with its receiver'
    specify '`//`       response: Comment'
    specify '`fn`       response: a function that will be described later'
    context '`()`' do
      it 'evalutes to a List'
      it 'evalutes each of its arguments ASTs in the context of the caller and places them into the list'
    end
  end

  describe 'Prototype (the root of the prototypical objects)' do
    it 'has no prototypes'
    it 'is where the prototype interface methods are defined'

    describe 'when the response is a function, f1' do
      it 'instead responds with f2, an object cloned from the f1'
      it 'sets `this` on the f2 to the receiver (so you don\'t have to put special rules in the interpreter for `this` like you do in js)'
    end
  end

  describe 'Extensible' do
    it 'has EntryPoints as a prototype'
    it 'has Literals as a prototype'
    it 'has Prototype as a prototype'
  end

  describe 'Function' do
    describe '() is the constructor' do
      it 'clones a new object and sets Function as its only prototype'
      it 'sets `argNames` to all arguments, except the last one'
      it 'sets `body` to the last argument'
      it 'sets `()` to its own `invoke`'
    end

    describe '`invoke`, which is `()` in clones' do
      context 'when invoked on a function' do
        it 'sets `that` to the object that sent the message (`this` was set when the function was looked up)'
        it 'sets `arguments` to the arguments, as ASTs' # list?
        it 'sets each of the function\'s argNames in its `responses`, their value is the AST at the same ordinal'
        it 'evalutes the body in the context of the function call, returning the response of its last line'
        # where did we get eval from?
        it 'evalutes to `nil` for an empty object'
        specify 'the interpreter\'s current object is the function'
      end
    end
  end

  describe 'Number' do
    it 'is the prototype of literal numbers'
    specify 'have a + message which adds two together'
    specify 'have an == message which compares their equality, returning true or false'
  end

  describe 'String' do
    it 'is the prototype of literal strings'
  end

  describe 'booleans (true / false)' do
  end

  describe 'nil' do
  end

  describe 'main' do
    # is Extensible
    # argv
    # env
    # stdin
    # stdout
    # stderr
    # exit()
  end


end

# need to talk about finding a message back in a prototype
    # and it calls another message on this,
    # which should start lookup on the object

# better tests on function receiver / sender
# when expression midway through is an error, it should stop evaluating

__END__
  do (
    some code evaluated in `that`
  )

  macro(
    some code evaluated in `this`
  )


  prottype message lookup should detect and avoid cycles


Array <-(each, fn(argName, body,
  <-(i, 0)
  while(i < (this length),
    that (fn(argName, body))(this at(i))
    <-(i, i + (1))
  )
))

; -----  EXAMPLE  -----
<-(wordCount, fn(str,
  <-(words, Hash withDefault(0))
  str split(" ") each(word,
    words update(word, word add(1)) ; expands to:   words set(word, words get(word) add(1))
  )
  words sortBy(key, value, value neg()) toHash
))

wordCount("def abc wat abc def abc")

; -----  EXPLANATION  -----
; `<-` is the message `<-` we look it up in the prototypes until we find it
;      it is a function that sets a variable on its receiver (main)
; `()` is sent to the `<-` function, which clones it, sets `that`, sets its `arguments` variable,
;      sets each of its parameter names as variables on it, whose value is the associated argument
;      evaluates the function
<-(wordCount, fn(str,
  <-(words, Hash withDefault(0))
  str split(" ") each(word,
    words update(word, word add(1)) ; expands to:   words set(word, words get(word) add(1))
  )
  words sortBy(key, value, value neg()) toHash
)

