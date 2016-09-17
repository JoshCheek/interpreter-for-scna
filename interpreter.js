// Can we see `this` from the caller?
// or set it in the evalMemberFunction?


// TODO: vars should be looked up in the enclosing lexical scope,
// NOT!!! earlier in the callstack
"use strict"

function p(obj) {
  console.dir(obj, {depth: 5, colors: true})
}

let esprima = require('esprima')

module.exports = (function() {
  // variables https://curiosity-driven.org/private-properties-in-javascript

  class AstFunction {
    constructor(name, params, body) {
      this.name   = name
      this.params = params
      this.body   = body
    }

    invoke(interpreter, args) {
      throw "Function invocation time!"
    }
  }

  class Interpreter {
    constructor(deps) {
      this.bionull = {
        name: 'null',
        jsprops: {}
      }

      const argv = {
        name: 'argv',
        type: 'array',
        value: deps.argv.map(s => ({type: 'string', value: s})),
        jsprops: {
          slice: {
            type:         'function',
            functionType: 'native',
            name:         'slice',
            body:         function(callee, args) {
              const ary    = callee.value
              const idx    = args[0].value
              const sliced = ary.slice(idx)
              return {jsprops:{}, value: sliced}
            },
          }
        },
      }
      const jsprocess = {
        name: 'process',
        type: 'object',
        jsprops: {
          argv: argv // should this be wrapped in one of our objects?
        }
      }
      this.jsglobal = {
        name: 'global',
        type: 'object',
        jsprops: {
          process: jsprocess,
        }
      }
      this.jsglobal.jsprops.global = this.jsglobal
      this.callstack = [{
        self:   this.jsglobal,
        vars:   {},
        result: this.bionull,
      }]
    }

    evalCode(code) {
      const ast = esprima.parse(code)
      return this.evaluate(ast)
    }

    evaluate(ast) {
      switch(ast.type) {
        case 'Program':
          ast.body.forEach(child => this.evaluate(child))
          break
        case 'VariableDeclaration':
          // add a variable to... uhm, top of stack?
          ast.declarations.forEach((child) => {
            this.evaluate(child)
          })
          break
        case 'VariableDeclarator':
          this.evalVarDeclaration(ast)
          break
        case 'FunctionExpression':
          this.evalFnExpr(ast)
          break
        case 'CallExpression':
          this.evalCallExpr(ast)
          break
        case 'MemberExpression':
          this.evalMemberExpr(ast)
          break
        case 'Identifier':
          this.evalIdent(ast)
          break
        case 'Literal':
          this.evalLiteral(ast)
          break
        case 'ExpressionStatement':
          this.evalExpressionStatement(ast)
          break
        case 'BinaryExpression':
          this.evalBinaryExpr(ast)
          break
        case 'IfStatement':
          this.evalIfStatement(ast)
          break
        case 'AssignmentExpression':
          this.evalAssignmentExpr(ast)
          break
        case 'BlockStatement':
          this.evalBlockStatement(ast)
          break
        case 'EmptyStatement':
          this.evalEmptyStatement(ast)
          break
        default:
          throw(`NEED A CASE FOR "${ast.type}" (${Object.keys(ast).join(' ')})`)
      }
      // for convenience
      return this.currentResult()
    }

    currentResult() {
      return this.frame().result
    }

    frame() {
      return this.callstack[this.callstack.length-1]
    }

    setReturn(value) {
      this.frame().result = value
    }

    evalVarDeclaration(ast) {
      const name  = extractName(ast.id)
      const value = this.evaluate(ast.init)
      if(this.callstack.length === 1) {
        this.jsglobal.jsprops[name] = value
      } else {
        this.frame().vars[name] = value
      }
    }

    evalFnExpr(ast) {
      this.setReturn({
        name:         extractName(ast.id),
        type:         'function',
        functionType: 'ast',
        ast:          ast.body,
        params:       ast.params,
      })
    }

    evalCallExpr(ast) {
      const fn   = this.evaluate(ast.callee)
      const args = ast.arguments.map(arg => this.evaluate(arg))
      if(fn.functionType === 'nst') {
        throw("handle ast functions")
      } else if (fn.functionType === 'native') {
        const callee = fn.callee || this.jsglobal
        const result = fn.body(callee, args)
        // p({
        //   callee: callee,
        //   result: result,
        //   args:   args,
        //   fn:     fn.__proto__,
        // })
        this.setReturn(result)
      } else {
        throw `Uhhh wat?`
      }
    }

    evalMemberExpr(ast) {
      // what happens here for process?
      // we should look it up in locals
      // then in scopes
      // then in global
      // p({
      //   when: "BEFORE EVALING MEMBER EXPR",
      // })
      const obj  = this.evaluate(ast.object)
      const name = ast.property.name
      let   prop = obj.jsprops[name]
      if(prop.type === 'function') {
        prop = Object.create(prop)
        prop.callee = obj
      }
      this.setReturn(prop)
    }

    evalIdent(ast) {
      const name   = extractName(ast)
      const stack  = this.callstack
      let   result = this.bionull
      // THIS IS WRONG! it shouldn't look up the callstack,
      // it should look in the enclosed variable scopes
      for(let i=stack.length-1; 0 <= i; --i) {
        let frame = stack[i]
        result = frame.vars[name]
        if(result) break
      }
      if(!result) result = this.jsglobal.jsprops[name]
      if(!result) result = this.bionull
      // console.log(">>>>>>>>>>>>>>>>>>")
      // p({
      //   name: name,
      //   stack: stack,
      //   result: result
      // })
      // console.log("<<<<<<<<<<<<<<<<<<<<")
      this.setReturn(result)
    }

    evalBinaryExpr(ast) {
      const operator = ast.operator
      const left     = this.evaluate(ast.left)
      const right    = this.evaluate(ast.right)
      if(operator === "+") {
        const result = left.value + right.value
        this.setReturn({type: "number", value: result})
      } else if(operator === "<") {
        const result = left.value < right.value
        this.setReturn({type: "boolean", value: result})
      } else if(operator === ">") {
        const result = left.value > right.value
        this.setReturn({type: "boolean", value: result})
      } else if(operator === "===") {
        const result = left.value === right.value
        this.setReturn({type: "boolean", value: result})
      } else {
        throw `Add a binary operator for: ${operator}`
      }
    }

    evalLiteral(ast) {
      let result
      if(typeof ast.value === "boolean") {
        result = {type: "boolean", value: ast.value}
      } else if(typeof ast.value === "number") {
        result = {type: "number", value: ast.value}
      } else if(typeof ast.value === "string") {
        result = {type: "string", value: ast.value}
      } else if(ast.value === null) {
        result = {type: "null", value: null}
      } else {
        p(ast)
        throw(`Whut? ${ast}`)
      }
      this.setReturn(result)
    }

    evalExpressionStatement(ast) {
      const expr = this.evaluate(ast.expression)
      this.setReturn(expr)
    }

    evalIfStatement(ast) {
      const condition = this.evaluate(ast.test)
      if(condition.value) {
        this.setReturn(this.evaluate(ast.consequent))
      } else if(ast.alternate) {
        this.setReturn(this.evaluate(ast.alternate))
      }
    }

    evalAssignmentExpr(ast) {
      // { type: 'AssignmentExpression',
      //   operator: '=',
      //   left: { type: 'Identifier', name: 'a' },
      //   right: { type: 'Literal', value: 2, raw: '2' } }
      const name  = extractName(ast.left)
      const value = this.evaluate(ast.right)
      this.frame().vars[name] = value
    }

    evalEmptyStatement(ast) {
    }

    evalBlockStatement(ast) {
      ast.body.forEach(expr => this.evaluate(expr))
    }
  }

  function extractName(identifierAst) {
    if(!identifierAst) return null
    return identifierAst.name
  }

  return Interpreter
})()
