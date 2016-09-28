"use strict"

function p(...objs) {
  objs.forEach(obj => console.dir(obj, {depth: 5, colors: true}))
}

const esprima = require('esprima')

module.exports = (function() {
  class Interpreter {
    constructor(deps) {
      this.jsnull = {name: 'null', type: 'null', value: null}

      this.callstack = [{
        self:   {},
        vars:   {},
        result: this.jsnull,
      }]
    }

    evalCode(code) {
      const ast = esprima.parse(code)
      return this.evaluate(ast)
    }

    setReturn(value) {
      this.frame().result = value
    }

    getResult() {
      return this.frame().result
    }

    frame() {
      return this.callstack[this.callstack.length-1]
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
        case 'ReturnStatement':
          this.EvalReturnStatement(ast)
          break
        default:
          throw(`NEED A CASE FOR "${ast.type}" (${Object.keys(ast).join(' ')})`)
      }
      // for convenience, return the result
      return this.getResult()
    }

    EvalProgram(ast) {
      p(ast)
      throw("EvalProgram")
    }

    EvalVariableDeclaration(ast) {
      p(ast)
      throw("EvalVariableDeclaration")
    }

    EvalVariableDeclarator(ast) {
      p(ast)
      throw("EvalVariableDeclarator")
    }

    EvalFunctionExpression(ast) {
      p(ast)
      throw("EvalFunctionExpression")
    }

    EvalCallExpression(ast) {
      p(ast)
      throw("EvalCallExpression")
    }

    EvalMemberExpression(ast) {
      p(ast)
      throw("EvalMemberExpression")
    }

    EvalIdentifier(ast) {
      p(ast)
      throw("EvalIdentifier")
    }

    EvalLiteral(ast) {
      let result
      if(typeof ast.value === "boolean") {
        p(ast)
        throw("EvalLiteral")
      } else if(typeof ast.value === "number") {
        p(ast)
        throw("EvalLiteral")
      } else if(typeof ast.value === "string") {
        p(ast)
        throw("EvalLiteral")
      } else if(ast.value === null) {
        p(ast)
        throw("EvalLiteral")
      } else {
        p(ast)
        throw(`Whut? ${ast}`)
      }
      this.setReturn(result)
    }

    EvalExpressionStatement(ast) {
      const returned = this.evaluate(ast.expression)
      this.setReturn(returned)
    }

    EvalBinaryExpression(ast) {
      let operator = ast.operator
      let result
      if(operator === "+") {
        p(ast)
        throw("EvalBinaryExpression")
      } else if(operator === "<") {
        p(ast)
        throw("EvalBinaryExpression")
      } else if(operator === ">") {
        p(ast)
        throw("EvalBinaryExpression")
      } else if(operator === "===") {
        p(ast)
        throw("EvalBinaryExpression")
      } else {
        throw `Add a binary operator for: ${operator}`
      }
      this.setReturn(result)
    }

    EvalIfStatement(ast) {
      p(ast)
      throw("EvalIfStatement")
    }

    EvalAssignmentExpression(ast) {
      p(ast)
      throw("EvalAssignmentExpression")
    }


    EvalBlockStatement(ast) {
      p(ast)
      throw("EvalBlockStatement")
    }

    EvalEmptyStatement(ast) {
      // noop
    }

    EvalReturnStatement(ast) {
      p(ast)
      throw("EvalReturnStatement")
    }
  }

  return Interpreter
})()
