function p(obj) {
  console.dir(obj, {depth: 3, colors: true})
}

module.exports = (function() {
  // variables https://curiosity-driven.org/private-properties-in-javascript

  class Interpreter {
    constructor() {
    }

    evaluate(ast) {
      switch(ast.type) {
        case 'Program':
          p(ast)
          break
        default:
          console.log(`NEED A CASE FOR ${ast.type} (${Object.keys(ast).join(' ')})`)
      }
    }
  }
  return Interpreter
})()
