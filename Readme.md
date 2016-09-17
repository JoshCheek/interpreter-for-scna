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

