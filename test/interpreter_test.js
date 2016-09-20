'use strict'

const assert      = require('chai').assert;
const Interpreter = require('../interpreter.js')

function buildInterpreter(opts) {
  if(!opts) opts = {}
  const argv = opts.argv || []
  return new Interpreter({argv: argv})
}

function assertEvaluates(input, expected, opts) {
  const interpreter = buildInterpreter(opts)
  const actual      = interpreter.evalCode(input)
  assert.deepEqual(actual, expected)
}

describe('Interpreter', function() {
  describe('interprets simple primitives', function() {
    specify('numbers', function() {
      assertEvaluates("1", {type: "number", value: 1})
    })
    specify('strings', function() {
      assertEvaluates("'a'", {type: "string", value: "a"})
    })
    specify('true', function() {
      assertEvaluates("true", {type: "boolean", value: true})
    })
    specify('false', function() {
      assertEvaluates("false", {type: "boolean", value: false})
    })
    specify('null', function() {
      assertEvaluates("null", {type: "null", value: null})
    })
  })

  describe('interprets simple math equations', function() {
    specify('addition', function() {
      assertEvaluates("1+2", {type: "number", value: 3})
    })
    specify('less than', function() {
      assertEvaluates("1<2", {type: "boolean", value: true})
      assertEvaluates("2<1", {type: "boolean", value: false})
    })
    specify('greater than', function() {
      assertEvaluates("1>2", {type: "boolean", value: false})
      assertEvaluates("2>1", {type: "boolean", value: true})
    })
    specify('comparison', function() {
      assertEvaluates("1 === 2", {type: "boolean", value: false})
      assertEvaluates("2 === 2", {type: "boolean", value: true})
    })
  })

  describe('simple variables', function() {
    it('can set and get a variable at the toplevel', function() {
      assertEvaluates("var a = 1; a", {type: "number", value: 1})
    })
    it('can use the variable in a more complex expression', function() {
      assertEvaluates("var a = 1; a+a", {type: "number", value: 2})
    })
    it('can set a variable it has previously set', function() {
      assertEvaluates("var a = 1; a = 2; a+a", {type: "number", value: 4})
    })
  })

  describe('grouping statements with a block', function() {
    it('evaluates each expression, resulting in the last', function() {
      assertEvaluates("{var a = 1; var b = 2; a+b}", {type: "number", value: 3})
    })
  })

  describe('if statements', function() {
    it('evaluates the body when the condition is true', function() {
      assertEvaluates("var a=1; if(true) a = 2; a", {type: "number", value: 2})
    })

    it('does not evaluate the body when the condition is false', function() {
      assertEvaluates("var a=1; if(false) a = 2; a", {type: "number", value: 1})
    })

    it('ignores the else clause when the condition is true', function() {
      assertEvaluates("var a=1; if(true) { a = 2 } else { a = 3 }; a", {type: "number", value: 2})
    })

    it('evalues the else clause when the condition is true', function() {
      assertEvaluates("var a=1; if(false) { a = 2 } else { a = 3 }; a", {type: "number", value: 3})
    })

    it('can handle complex conditionals', function() {
      assertEvaluates("var a=1; if(1 === 2) { a = 2 } else { a = 3 }; a", {type: "number", value: 3})
      assertEvaluates("var a=1; if(2 === 2) { a = 2 } else { a = 3 }; a", {type: "number", value: 2})
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
      interprets(
        "process.argv",
        { type: 'array', value: [{type: 'string', value: 'a'}] },
        {argv: ['a']}
      )
    })
  })

  describe('native function invocation', function() {
    it('can slice argv', function() {
      interprets(
        "process.argv.slice(1)",
        { type: 'array', value: [{type: 'string', value: 'b'}, {type: 'string', value: 'c'}] },
        {argv: ['a', 'b', 'c']}
      )
      interprets(
        "process.argv.slice(2)",
        { type: 'array', value: [{type: 'string', value: 'c'}] },
        {argv: ['a', 'b', 'c']}
      )
    })
  })
})
// // native functions
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
