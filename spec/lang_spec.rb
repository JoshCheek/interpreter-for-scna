# From my lisp implementation (https://gist.github.com/JoshCheek/346f8796d057c57ab471f2fe32694ec8),
# this is what I needed to write a basic program:
# Lists:                car cdr cons            | handled by Literals ()
# Logic:                or and if true false    | ?
# Multiple expressions: progression             | ? maybe `do` which evalutes its args in the caller
# side effects:         print_num               | ?
# Numbers:              zero succ pred is_zero  | we have them

require 'biolangual'
RSpec.describe 'Interpreting Biolangual' do
  describe 'an object is a function (invoked by the interpreter directly) that implements message passing by' do
    describe 'receiving `receiver`, `sender`, `message`, `arguments`' do
      specify '`receiver`  the object getting the message'
      specify '`sender`    the object giving the message'
      specify '`message`   the data passing from the sender to the receiver, always a string for now'
      specify '`arguments` is a list of objects needed for responding to the message'
    end
    describe 'returning one of `response` or `error` and their associated data' do
      # maybe others, too, I haven\'t really thought about what would be possible (eg maybe you could get continuations by being clever with it)
      specify 'a `response`\'s data is an object to be given back to the caller'
      specify 'an `error`\'s data is a description of what went wrong (start with a string)'
    end
  end

  describe 'literals (objects that are created with syntax)' do
    specify 'can be numbers, objects which represent floats'
    specify 'can be strings, objects which wrap strings'
  end

  describe 'expressions' do
    specify 'can begin with a literal, in which case they evalute to that literal'
    specify 'can begin with a message, in which case it is sent to the current object (responding will be described later)'
    specify 'messages after the first are sent to the response of the the expression to their left'
    specify 'when a message is sent to an object that doesn\'t respond to it it raises an error'
  end

  describe 'All objects are prototypical unless they explicitly specify otherwise' do
    specify 'they must respond to `responses` and `prototypes`'
    specify '`responses` is an associative array of strings and their responses'
    specify '`prototypes` is a list of other places to look for responses'
    specify 'inheritance / message lookup' do
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

  describe 'execution context' do
    specify 'there is always an object, the default object is main'
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
    describe 'responses' do
      describe '`<-`'
        # sets it on the object, regardless of whether its on prototype
      specify '`<-` responds with a function that will set a message on the `receiver`'
      specify '`clone` responds with a new object and sets the receiver as its only prototype'
      specify '`responses` is an associative array of strings and their responses'
      specify '`prototypes` is a list of other places to look for responses'
    end

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
    specify '() is the constructor' do
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

