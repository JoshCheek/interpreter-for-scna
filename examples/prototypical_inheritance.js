var o1 = {v1: 1, v2: 2, v3: 3}

var o2 = Object.create(o1)
o2.v2 = 4

var o3 = Object.create(o2)
o3.v3 = 5

console.log(o3.v1)
console.log(o3.v2)
console.log(o3.v3)
