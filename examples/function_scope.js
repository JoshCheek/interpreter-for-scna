var a1 = 1
var a2 = 2
var a3 = 3

var f = function() {
  var a2 = 4
  return function() {
    var a3 = 5
    return {a1: a1, a2: a2, a3: a3}
  }
}

console.log(f()())
