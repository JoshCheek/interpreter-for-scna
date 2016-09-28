'use strict'
const stream = require('stream')

function p(...objs) {
  objs.forEach(obj => console.dir(obj, {depth: 5, colors: true}))
}


const assert      = require('chai').assert;
const Interpreter = require('../interpreter.js')

function buildInterpreter(opts) {
  if(!opts) opts = {}
  const argv   = opts.argv || []
  const stdout = opts.stdout || stream.Writable({write: function() {return true}})
  return new Interpreter({argv: argv, stdout: stdout})
}

function assertEvaluates(input, expected, opts) {
  const interpreter = buildInterpreter(opts)
  const actual      = interpreter.evalCode(input)
  for(let name in expected) {
    assert.deepEqual(actual[name], expected[name])
  }
}

describe('Interpreter', function() {
  describe('tracks the object that represents singletons', function() {
    specify('jsnull will give us our `null` object, it has a name, type, and value (so that it can work in a wide variety of places', function() {
      assert.deepEqual(buildInterpreter().jsnull, {name: 'null', type: 'null', value: null})
    })
    specify('jstrue will give us our `true` object, it has a name, type, and value (so that it can work in a wide variety of places', function() {
      assert.deepEqual(buildInterpreter().jstrue, {name: 'true', type: 'boolean', value: true})
    })
    specify('jsfalse will give us our `false` object, it has a name, type, and value (so that it can work in a wide variety of places', function() {
      assert.deepEqual(buildInterpreter().jsfalse, {name: 'false', type: 'boolean', value: false})
    })
  })

  describe('interprets simple primitives', function() {
    specify('numbers', function() {
      assertEvaluates("1", {type: "number", value: 1})
    })
    specify('strings', function() {
      assertEvaluates("'a'", {type: "string", value: "a"})
    })
    specify('`true` always evaluates to our singleton true object', function() {
      const interpreter = buildInterpreter()
      assert.deepEqual(interpreter.evalCode('true'), interpreter.jstrue)
    })
    specify('`false` always evaluates to our singleton false object', function() {
      const interpreter = buildInterpreter()
      assert.deepEqual(interpreter.evalCode('false'), interpreter.jsfalse)
    })
    specify('`null` always evaluates to our singleton null object', function() {
      const interpreter = buildInterpreter()
      assert.deepEqual(interpreter.evalCode('null'), interpreter.jsnull)
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
    it('can set a variable at the toplevel', function() {
      const interpreter = buildInterpreter()
      interpreter.evalCode('var a = 1')
      const expected = {type: 'number', value: 1}
      const actual   = interpreter.frame().vars['a']
      assert.deepEqual(actual, expected)
    })
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
      const interp = buildInterpreter({argv: []})
      const argv   = interp.jsglobal.jsprops.process.jsprops.argv
      assert.equal(argv.type, "array")
      assert.deepEqual(argv.value, [])
    })

    specify('argv\'s args are internal strings', function() {
      const interp = buildInterpreter({argv: ['arg1', 'arg2']})
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

    // NOTE: This is true in the node REPL, but not when running it against a file
    // https://twitter.com/josh_cheek/status/781047943696674816
    // It's possibly a bug:
    // https://github.com/nodejs/node-v0.x-archive/issues/6254
    specify('when a variable is set at the toplevel, it is saved on the global object', function() {
      const interp = buildInterpreter()
      interp.evalCode("var a = 1")
      assert.deepEqual(interp.jsglobal.jsprops.a, {type: "number", value: 1})
    })

    it('looks up successive property invocations on the result of the previous one', function() {
      assertEvaluates(
        "process.argv",
        { type: 'array', value: [{type: 'string', value: 'a'}] },
        {argv: ['a']}
      )
    })
  })

  describe('defining and calling functions / lexical scope', function() {
    it('can create an anonymous function', function() {
      assertEvaluates(
        "(function(a) { return 12 })",
        {type: 'FunctionExpression'}
      )
    })

    it('stores the function\'s lexical scope, the vars of the stack frame it was defined in', function() {
      const interpreter = buildInterpreter()
      const actual      = interpreter.evalCode(
        "var x = 12; (function() {})"
      )
      assert.deepEqual(actual.lexicalScope.x, {type: 'number', value: 12})
    })

    it('updates the stack frame\'s return value with the function result', function() {
      assertEvaluates(
        "(function() { return 12 })()",
        { type: 'number', value: 12 }
      )
    })

    it('defaults the function body to null (implies it gets its own stack frame)', function() {
      assertEvaluates("(function() {})()", { type: 'null' })
    })

    it('can pass an argument to the function', function() {
      assertEvaluates(
        "(function(a) { return a+a })(1)",
        { type: 'number', value: 2 }
      )
    })

    it('keeps the functions arguments in a separate stack frame', function() {
      assertEvaluates(
        "var a = 1; (function(a) { return a })(2)",
        {type: 'number', value: 2}
      )
    })

    it('removes the stack frame after the function invocation', function() {
      assertEvaluates(
        "var a = 1; (function(a) { return a })(2); a",
        {type: 'number', value: 1}
      )
    })

    it('can invoke a function with multiple argumnts', function() {
      assertEvaluates(
        "(function(a, b) { return a+b })(2, 3)",
        {type: 'number', value: 5}
      )
    })

    it('can save a function, look it up, and invoke it', function() {
      assertEvaluates(
        "var fn = function(a) { return a }; fn(2)",
        {type: 'number', value: 2}
      )
    })

    it('looks in the lexical scope if it does not have the argument', function() {
      assertEvaluates(
        "var a = 1; (function(b) { return a+b })(2)",
        {type: 'number', value: 3}
      )
    })

    it('uses the defining environment\'s vars for the function\'s lexical scope, not, for example, the base vars', function() {
      assertEvaluates(
        `var a = 1;
        (function(b) {
          return function(c) { return a+b+c }
        })(2)(3)`,
        {type: 'number', value: 6}
      )
    })

    it('allows functions to look up variables that they have set', function() {
      assertEvaluates(
        "var a = 1; (function() { var a = 2; return a })()",
        {type: 'number', value: 2}
      )
    })

    it('sets variables in the function\'s vars, not the lexical scope\'s vars', function() {
      assertEvaluates(
        `var a = 1;
        (function() { var a = 2 })()
        a`,
        {type: 'number', value: 1}
      )
    })
  })

  describe('simple objects', function() {
    it('has no visble properties by default', function() {
      assertEvaluates(
        "({})",
        {type: 'object', jsprops: {}}
      )
    })

    it('can have properties from its definition', function() {
      assertEvaluates(
        "({num: 12})",
        {type: 'object', jsprops: {num: {type: 'number', value: 12}}}
      )
    })

    it('can set properties (you\'ll need to explicitly check in EvalMemberExpression)', function() {
      assertEvaluates(
        "var obj = {}; obj.num = 13; obj",
        {type: 'object', jsprops: {num: {type: 'number', value: 13}}}
      )
    })

    it('can look up properties', function() {
      assertEvaluates(
        "var obj = {num: 14}; obj.num",
        {type: 'number', value: 14}
      )
    })

    it('can look up properties several levels deep', function() {
      assertEvaluates(
        "var a = {b: 1}; var c = {d: a}; c.d.b",
        {type: 'number', value: 1}
      )
    })
  })

  describe('this', function() {
    it('is the global object at the top-level', function() {
      const interpreter = buildInterpreter()
      assert.deepEqual(interpreter.frame().self, interpreter.jsglobal)

      const actual = interpreter.evalCode('this')
      assert.deepEqual(actual, interpreter.jsglobal)
    })

    it('is set to the object a function was called on', function() {
      assertEvaluates(`
        var num = 1
        var obj = {
          num: 2,
          getNum: function() {
            return this.num
          }
        }
        obj.getNum()
      `,
        {type: 'number', value: 2}
      )
    })

    it('is set to the global object, when a function is not called on an object', function() {
      assertEvaluates(`
        var num = 1
        var obj = {
          num: 2,
          getGlobalNum: function() {
            return (function() { return this.num })()
          }
        }
        obj.getGlobalNum()
      `,
        {type: 'number', value: 1}
      )
    })
  })


  describe('native function invocation (will require modifications to EvalCallExpression)', function() {
    it('can slice argv', function() {
      assertEvaluates(
        "process.argv.slice(1)",
        { type: 'array', value: [{type: 'string', value: 'b'}, {type: 'string', value: 'c'}] },
        {argv: ['a', 'b', 'c']}
      )
      assertEvaluates(
        "process.argv.slice(2)",
        { type: 'array', value: [{type: 'string', value: 'c'}] },
        {argv: ['a', 'b', 'c']}
      )
      assertEvaluates(
        "process.argv.slice(2); process.argv",
        { type: 'array', value: [{type: 'string', value: 'a'}, {type: 'string', value: 'b'}, {type: 'string', value: 'c'}] },
        {argv: ['a', 'b', 'c']}
      )
    })

    it('can log to the console', function(done) {
      let written  = ""
      const stdout = {write: function(text) {
        assert.equal(text, "hello\n")
        done()
        return true
      }}
      const interpreter = buildInterpreter({stdout: stdout})
      const actual = interpreter.evalCode("console.log('hello')")
      assert.equal(actual.type,  "null")
    })
  })
})

// prototypical inheritance
// builtins: forEach, split, console.log, process.exit
