// Can we see `this` from the caller?
// or set it in the evalMemberFunction?


// TODO: vars should be looked up in the enclosing lexical scope,
// NOT!!! earlier in the callstack
"use strict"
function p(obj) {
  console.dir(obj, {depth: 5, colors: true})
}

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
        bioprops: {}
      }

      const realArgv = deps.argv
      const argv = {
        name: 'argv',
        bioprops: {
          slice: {
            type:         'function',
            functionType: 'native',
            name:         'slice',
            body:         function(callee, args) {
              const ary    = callee.data
              const idx    = args[0].value
              const sliced = ary.slice(idx)
              return {bioprops:{}, data: sliced}
            },
          }
        },
        data: realArgv
      }
      const bioprocess = {
        name: 'process',
        bioprops: {
          argv: argv // should this be wrapped in one of our objects?
        }
      }
      this.bioglobal = {
        name: 'global',
        bioprops: {
          process: bioprocess,
        }
      }
      this.bioglobal.bioprops['global'] = this.bioglobal
      this.callstack = [{
        self:   this.bioglobal,
        vars:   {},
        result: this.bionull,
      }]
    }

    evaluate(ast) {
      // const toPrint = {
      //   ast: ast.type,
      //   ret: this.currentResult(),
      // }
      // if(ast.id)
      //   toPrint.name = extractName(ast.id)
      // p(toPrint)
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
        default:
          throw(`NEED A CASE FOR "${ast.type}" (${Object.keys(ast).join(' ')})`)
      }
      // for convenience
      // p({ast: ast.type, result: this.currentResult()})
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
      this.frame().vars[name] = value
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
        const callee = fn.callee || this.bioglobal
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
      let   prop = obj.bioprops[name]
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
      if(!result) result = this.bioglobal.bioprops[name]
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

    evalLiteral(ast) {
      if(typeof ast.value === "boolean") {
        p(ast)
        throw("do smth")
      } else if(typeof ast.value === "number") {
        this.setReturn({ type: "number", value: ast.value })
      } else if(typeof ast.value === "string") {
        p(ast)
        throw("do smth")
      } else if(ast.value === null) {
        p(ast)
        throw("do smth")
      } else {
        p(ast)
        throw(`Whut? ${ast}`)
      }
    }

    evalExpressionStatement(ast) {
      const expr = this.evaluate(ast.expression)
      this.setReturn(expr)
    }
  }

  function extractName(ast) {
    if(!ast) return null
    return ast.name
  }

  return Interpreter
})()
