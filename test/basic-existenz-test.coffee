assert = require 'assert'
should = require 'should'

describe 'WHEN loading the module', ->
  index = require '../lib/index'

  it 'should exist', ->
    should.exist index