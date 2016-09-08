; * An object is a hash of variables with a list of prototypes
; * The default object is `main`
; * The expressions are of the form `message (" "* message)*`
;   (one or more messages adjacent to each other, delimited by whitespace)
; * The first message in a list of messages is sent to the current object
; * The message after it is sent to its return value

; * The message ';' ignores all messages sent to it, and is a comment
; * The message `<-` will set a key/value pair on the receiver unless overridden
; * The message `()` is special in that it can includes a list of comma delimited arguments
;   The arguments are stored as ASTs
; * The message `identity` will return the current object by default
; * The message `fn` is used to create an object that is a function, it will set:
;   * argNames  (names of the arguments the method expects to be set)
;   * this      (object the message was sent to)
;   And when it is invoked (by the `()` method), it will also have access to:
;   * arguments (array of arg asts)
;   * that      (object the message was sent from)

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

wordCount("def abc wat abc def abc")
