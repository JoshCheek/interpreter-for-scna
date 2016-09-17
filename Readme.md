JSCNA
=====

What
----

We're going to implement a tiny subset of JavaScript, for the purpose of
learning about interpreters at a [SCNA](http://scna.softwarecraftsmanship.com/events/)
workshop.


Setup
-----

Get node.js in whatever way you do that. For me, on a mac:

```sh
$ brew install node
```

For clarity, I'm using

```sh
$ node --version
v6.4.0
```

Install the dependencies (Node should ship with npm):

```sh
$ npm install
```


Running the tests
-----------------

Run once.

```sh
$ npm run test
```

Run repeatedly, stopping after the first failure.

```sh
$ npm run test_progression
```


Running your interpreter
------------------------

The `-p` flag, we're using to have it print the result out (similar but not the same as node)
So you can see intermediate bits by running it against a file, using this flag.

```
$ bin/jss -p examples/1_number.js
```
