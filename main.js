function inspect(obj) {
  console.dir(obj, {depth: 4, colors: true})
}

module.exports = (function() {
  // variables https://curiosity-driven.org/private-properties-in-javascript

  class Interpreter {
    constructor() {
    }

    evaluate(ast) {
      inspect(ast)
    }
  }
  return Interpreter
})()
