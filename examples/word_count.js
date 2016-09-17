var count_words = function(str) {
  var count = 0
  str.split(" ").forEach(function(word) { count = count + 1 })
  return count
}


// 0: node bin, 1: this filename, 2: our argv
var argv = process.argv.slice(2)

console.log(argv)

if(argv.length > 0) {
  console.log(count_words(argv[0]))
} else {
  console.log("You must provide an argument to count")
  process.exit(1)
}
