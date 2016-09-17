'use strict'

const assert      = require('chai').assert;
const Interpreter = require('../interpreter.js')

function interprets(opts) {
  let input       = opts.in
  let expected    = opts.out
  let interpreter = new Interpreter({argv: []})
  let actual      = interpreter.evalCode(input)
  assert.deepEqual(actual, expected)
}

describe('Interpreter', function() {
  describe('interprets simple primitives', function() {
    specify('numbers', function() {
      interprets({in: "1", out: {type: "number", value: 1}})
    })
    specify('strings', function() {
      interprets({in: "'a'", out: {type: "string", value: "a"}})
    })
    specify('true', function() {
      interprets({in: "true", out: {type: "boolean", value: true}})
    })
    specify('false', function() {
      interprets({in: "false", out: {type: "boolean", value: false}})
    })
    specify('null', function() {
      interprets({in: "null", out: {type: "null", value: null}})
    })
  })
})

// // number operators
// "1 + 2"
// "1 < 2"
// "1 > 2"
// "1 === 1"
// "1 === 2"

// // start getting a stack
// "var a = 1"
// "var a = 1; a"
// "var a = 1; a + a"

// // if statements
// "var a=1; if(true) a = 2"
// "var a=1; if(false) a = 2"
// "var a=1; if(1 === 1) { a = 2 } else { a = 3 }"
// "var a=1; if(1 === 2) { a = 2 } else { a = 3 }"

// // looking up objs
// "process"
// "process.argv"

// // native functions
// "process.argv.slice(1)"
// "process.argv.slice(2)"
// "console"
// "console.log('hello')"

// // Stack
//   // return values
//   "var f = function() { return 123 }; f()"
//   "var f = function() { 123 }; f()"

//   "var f = function() { return 1 }; var g = function() { return f() }; g()"
//   "var f = function() { return 1 }; var g = function() { return f()+2 }; g()"

//   // local vars
//   "var a=1; var b = 20; var f = function() { var a = 2; return a + b }; f()"

//   // variable access is based on the lexical scope
//   `var a1 = 1; var a2 = 2; var a3 = 3;
//    var f = function() {
//      var a2 = 4
//      return function() { var a3 = 5 }
//    }
//    f()()`
//    "var a = 1; var f = function() { return a }; var g = function() { var a = 3; return f() }; g()"

//   // args
//   "var f = function(x) { return x + 1 }; f(10)" // 11

// // prototypical inheritance


// // builtins: forEach, split, console.log, process.exit
