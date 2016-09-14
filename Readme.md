Biolangual
==========

What
----

An object oriented programming language, created for the purpose of
learning by implementing its interpreter.

Created for a workshop at [SCNA](http://scna.softwarecraftsmanship.com/events/).


The name
--------

The language is heavily inspired by the programming language [IO](http://iolanguage.org),
hence the "io" in its name. It is deeply object oriented, which should be a domain more than a paradigm,
the domain of biology (and many other things), so I stuck a "b" in front of "io" to represent this.
Programming languages often stick the word "lang" after them, which would make it bio-lang,
which is pretty close to bilingual, so fuck it, lets call it "Biolangual"


Unorganized
-----------

We're going to make a variant of IO. Why a variant?
We don't have enough time to adhere to all the real requirements.
Why IO? Its syntax is sparse, and its an interesting take on OO
(plus, there's tons of lisp tutorials out there)


```js
Array <-(each, fn(argName, body,
  <-(i, 0)
  while(i < (this length),
    that (fn(argName, body))(this at(i))
    <-(i, i + (1))
  )
))

// -----  EXAMPLE  -----
<-(wordCount, fn(str,
  <-(words, Hash withDefault(0))
  str split(" ") each(word,
    words update(word, word add(1)) ; expands to:   words set(word, words get(word) add(1))
  )
  words sortBy(key, value, value neg()) toHash
))

wordCount("def abc wat abc def abc")

// -----  EXPLANATION  -----
// `<-` is the message `<-` we look it up in the prototypes until we find it
//      it is a function that sets a variable on its receiver (main)
// `()` is sent to the `<-` function, which clones it, sets `that`, sets its `arguments` variable,
//      sets each of its parameter names as variables on it, whose value is the associated argument
//      evaluates the function
<-(wordCount, fn(str,
  <-(words, Hash withDefault(0))
  str split(" ") each(word,
    words update(word, word add(1)) ; expands to:   words set(word, words get(word) add(1))
  )
  words sortBy(key, value, value neg()) toHash
)
```
