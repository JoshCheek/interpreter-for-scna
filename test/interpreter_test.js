'use strict'

const assert       = require('chai').assert;
const interpreter  = require('../promises.js')
const executeLater = function(fn) { setTimeout(fn, 0) }

describe('whatev', function() {
  it('is a test 1', function() {
    assert.equal(resolve_cb.constructor, Function)
    assert.equal(reject_cb.constructor,  Function)
  })

  it('is a test 2', function() {
    assert(true)
  })
})
