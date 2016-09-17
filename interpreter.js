"use strict"

function p(obj) {
  console.dir(obj, {depth: 5, colors: true})
}

let esprima = require('esprima')

module.exports = (function() {
  class Interpreter {
    evalCode(code) {
      const ast = esprima.parse(code)
      return this.evaluate(ast)
    }

    evaluate(ast) {
      switch(ast.type) {
        case 'Program':
          this.EvalProgram(ast)
          break
        case 'VariableDeclaration':
          this.EvalVariableDeclaration(ast)
          break
        case 'VariableDeclarator':
          this.EvalVariableDeclarator(ast)
          break
        case 'FunctionExpression':
          this.EvalFunctionExpression(ast)
          break
        case 'CallExpression':
          this.EvalCallExpression(ast)
          break
        case 'MemberExpression':
          this.EvalMemberExpression(ast)
          break
        case 'Identifier':
          this.EvalIdentifier(ast)
          break
        case 'Literal':
          this.EvalLiteral(ast)
          break
        case 'ExpressionStatement':
          this.EvalExpressionStatement(ast)
          break
        case 'BinaryExpression':
          this.EvalBinaryExpression(ast)
          break
        case 'IfStatement':
          this.EvalIfStatement(ast)
          break
        case 'AssignmentExpression':
          this.EvalAssignmentExpression(ast)
          break
        case 'BlockStatement':
          this.EvalBlockStatement(ast)
          break
        case 'EmptyStatement':
          this.EvalEmptyStatement(ast)
          break
        default:
          throw(`NEED A CASE FOR "${ast.type}" (${Object.keys(ast).join(' ')})`)
      }
      // for convenience, return the result
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

    evalEmptyStatement(ast) {
    }

    constructor(deps) {
      this.jsnull = {name: 'null', type: 'null', value: null}

      const arraySlice = {
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

      const argv = { name: 'argv', type: 'array',
        value: deps.argv.map(s => ({type: 'string', value: s})),
        jsprops: { slice: arraySlice },
      }

      const jsprocess = { name: 'process', type: 'object',
        jsprops: { argv: argv }
      }

      this.jsglobal = {name: 'global', type: 'object',
        jsprops: { process: jsprocess }
      }
      this.jsglobal.jsprops.global = this.jsglobal

      this.callstack = [{
        self:   this.jsglobal,
        vars:   {},
        result: this.jsnull,
      }]
    }

    EvalProgram(ast) {
      ast.body.forEach(child => this.evaluate(child))
    }

    EvalVariableDeclaration(ast) {
      ast.declarations.forEach((child)=> {
        this.evaluate(child)
      })
    }

    EvalVariableDeclarator(ast) {
      const name  = extractName(ast.id)
      const value = this.evaluate(ast.init)
      if(this.callstack.length === 1) {
        this.jsglobal.jsprops[name] = value
      } else {
        this.frame().vars[name] = value
      }
    }

    EvalFunctionExpression(ast) {
      this.setReturn({
        name:         extractName(ast.id),
        type:         'function',
        functionType: 'ast',
        ast:          ast.body,
        params:       ast.params,
      })
    }

    EvalCallExpression(ast) {
      const fn   = this.evaluate(ast.callee)
      const args = ast.arguments.map(arg => this.evaluate(arg))
      if(fn.functionType === 'nst') {
        throw("handle ast functions")
      } else if (fn.functionType === 'native') {
        const callee = fn.callee || this.jsglobal
        const result = fn.body(callee, args)
        this.setReturn(result)
      } else {
        throw `Uhhh wat?`
      }
    }

    EvalMemberExpression(ast) {
      const obj  = this.evaluate(ast.object)
      const name = ast.property.name
      let   prop = obj.jsprops[name]
      if(prop.type === 'function') {
        prop = Object.create(prop)
        prop.callee = obj
      }
      this.setReturn(prop)
    }

    EvalIdentifier(ast) {
      const name   = extractName(ast)
      const stack  = this.callstack
      let   result = this.jsnull
      // THIS IS WRONG! it shouldn't look up the callstack,
      // it should look in the enclosed variable scopes
      for(let i=stack.length-1; 0 <= i; --i) {
        let frame = stack[i]
        result = frame.vars[name]
        if(result) break
      }
      if(!result) result = this.jsglobal.jsprops[name]
      if(!result) result = this.jsnull
      this.setReturn(result)
    }

    EvalLiteral(ast) {
      let result
      if(typeof ast.value === "boolean") {
        result = {type: "boolean", value: ast.value}
      } else if(typeof ast.value === "number") {
        result = {type: "number", value: ast.value}
      } else if(typeof ast.value === "string") {
        result = {type: "string", value: ast.value}
      } else if(ast.value === null) {
        result = this.jsnull
      } else {
        p(ast)
        throw(`Whut? ${ast}`)
      }
      this.setReturn(result)
    }

    EvalExpressionStatement(ast) {
      const expr = this.evaluate(ast.expression)
      this.setReturn(expr)
    }

    EvalBinaryExpression(ast) {
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

    EvalIfStatement(ast) {
      const condition = this.evaluate(ast.test)
      if(condition.value) {
        this.setReturn(this.evaluate(ast.consequent))
      } else if(ast.alternate) {
        this.setReturn(this.evaluate(ast.alternate))
      }
    }

    EvalAssignmentExpression(ast) {
      // { type: 'AssignmentExpression',
      //   operator: '=',
      //   left: { type: 'Identifier', name: 'a' },
      //   right: { type: 'Literal', value: 2, raw: '2' } }
      const name  = extractName(ast.left)
      const value = this.evaluate(ast.right)
      this.frame().vars[name] = value
    }


    EvalBlockStatement(ast) {
      ast.body.forEach(expr => this.evaluate(expr))
    }

    EvalEmptyStatement(ast) {
    }
  }

  function extractName(identifierAst) {
    if(!identifierAst) return null
    return identifierAst.name
  }

  return Interpreter
})()
