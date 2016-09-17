'use strict'

const assert      = require('chai').assert;
const Interpreter = require('../interpreter.js')

function buildInterpreter(opts={}) {
  let argv = opts.argv || []
  return new Interpreter({argv: argv})
}

function interprets(opts) {
  let input       = opts.in
  let expected    = opts.out
  let interpreter = buildInterpreter(opts)
  let actual      = interpreter.evalCode(input)

  for(let name in expected) {
    assert.deepEqual(actual[name], expected[name])
  }
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

  describe('interprets simple math equations', function() {
    specify('addition', function() {
      interprets({in: "1+2", out: {type: "number", value: 3}})
    })
    specify('less than', function() {
      interprets({in: "1<2", out: {type: "boolean", value: true}})
      interprets({in: "2<1", out: {type: "boolean", value: false}})
    })
    specify('greater than', function() {
      interprets({in: "1>2", out: {type: "boolean", value: false}})
      interprets({in: "2>1", out: {type: "boolean", value: true}})
    })
    specify('comparison', function() {
      interprets({in: "1 === 2", out: {type: "boolean", value: false}})
      interprets({in: "2 === 2", out: {type: "boolean", value: true}})
    })
  })

  describe('simple variables', function() {
    it('can set and get a variable at the toplevel', function() {
      interprets({in: "var a = 1; a", out: {type: "number", value: 1}})
    })
    it('can use the variable in a more complex expression', function() {
      interprets({in: "var a = 1; a+a", out: {type: "number", value: 2}})
    })
    it('can set a variable it has previously set', function() {
      interprets({in: "var a = 1; a = 2; a+a", out: {type: "number", value: 4}})
    })
  })

  describe('grouping statements with a block', function() {
    it('evaluates each expression, resulting in the last', function() {
      interprets({in: "{var a = 1; var b = 2; a+b}", out: {type: "number", value: 3}})
    })
  })

  describe('if statements', function() {
    it('evaluates the body when the condition is true', function() {
      interprets({in: "var a=1; if(true) a = 2; a", out: {type: "number", value: 2}})
    })

    it('does not evaluate the body when the condition is false', function() {
      interprets({in: "var a=1; if(false) a = 2; a", out: {type: "number", value: 1}})
    })

    it('ignores the else clause when the condition is true', function() {
      interprets({in: "var a=1; if(true) { a = 2 } else { a = 3 }; a", out: {type: "number", value: 2}})
    })

    it('evalues the else clause when the condition is true', function() {
      interprets({in: "var a=1; if(false) { a = 2 } else { a = 3 }; a", out: {type: "number", value: 3}})
    })

    it('can handle complex conditionals', function() {
      interprets({in: "var a=1; if(1 === 2) { a = 2 } else { a = 3 }; a", out: {type: "number", value: 3}})
      interprets({in: "var a=1; if(2 === 2) { a = 2 } else { a = 3 }; a", out: {type: "number", value: 2}})
    })
  })

  describe('the global object', function() {
    it('is accessible at the toplevel of the interpreter', function() {
      const global = buildInterpreter().jsglobal
      assert.equal(typeof global, "object")
    })

    it('has the type "object"', function() {
      const global = buildInterpreter().jsglobal
      assert.equal(global.type, "object")
    })

    it('has jsprops to store its properties', function() {
      const global = buildInterpreter().jsglobal
      assert.equal(typeof global.jsprops, "object")
    })

    specify('one of its properties is "global", which returns itself', function() {
      const global = buildInterpreter().jsglobal
      assert.deepEqual(global.jsprops.global, global)
    })

    specify('one of its properties is "process", which returns another object', function() {
      const global  = buildInterpreter().jsglobal
      const process = global.jsprops.process
      assert.equal(process.type, "object")
    })

    specify('process contains another variable, `argv`, which is an array wrapping argv', function() {
      const interp = new Interpreter({argv: []})
      const argv   = interp.jsglobal.jsprops.process.jsprops.argv
      assert.equal(argv.type, "array")
      assert.deepEqual(argv.value, [])
    })

    specify('argv\'s args are internal strings', function() {
      const interp = new Interpreter({argv: ['arg1', 'arg2']})
      assert.deepEqual(interp.jsglobal.jsprops.process.jsprops.argv.value, [
        {type: "string", value: 'arg1'},
        {type: "string", value: 'arg2'},
      ])
    })
  })

  describe('slightly more interesting variable lookup', function() {
    specify('when a variable can\'t be found, it is looked up on the global object', function() {
      const interp = buildInterpreter()
      let result

      result = interp.evalCode("global")
      assert.equal(result, interp.jsglobal)

      result = interp.evalCode("process")
      assert.equal(result, interp.jsglobal.jsprops.process)
    })

    specify('when a variable is set at the toplevel, it is saved on the global object', function() {
      const interp = buildInterpreter()
      interp.evalCode("var a = 1")
      assert.deepEqual(interp.jsglobal.jsprops.a, {type: "number", value: 1})
    })

    it('looks up successive property invocations on the result of the previous one', function() {
      interprets({
        argv: ['a'],
        in: "process.argv",
        out: {
          type: 'array',
          value: [{type: 'string', value: 'a'}]
        },
      })
    })
  })

})

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
