should = require 'should'
helper = require './support/helper'
_ = require 'underscore'
mongoose = require 'mongoose'
ObjectId = mongoose.Types.ObjectId

sampleUsers = null

describe 'WHEN working with store.users.lookup', ->

  before (done) ->
    helper.start null, done

  after (done) ->
    helper.stop done

  it 'should exist', ->
    should.exist helper.store.users.lookup

  describe 'WHEN running against an empty database', ->
    describe 'WHEN invoking lookup', ->
      it 'WITH empty parameters IT should return an empty list', (done) ->
        helper.store.users.lookup "a",{}, (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 0
          done()

  describe 'WHEN running against a sample database', ->
    it 'SETTING UP SAMPLE', (done) ->
      sampleUsers = helper.addSampleUsers done

    ###
    it "DUMP", (done) ->
      helper.dumpCollection('users') ->
        done()
    ###
    describe 'WHEN invoking lookup', ->
      it 'WITH empty parameters IT should return a full list', (done) ->
        helper.store.users.lookup '',{}, (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 10
          done()

      it 'WITH searching for Al IT should return a list of 10 users', (done) ->
        helper.store.users.lookup 'Al',{}, (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 10
          done()

      it 'WITH searching for Al and limit 5 IT should return a list of 5 users', (done) ->
        helper.store.users.lookup 'Al',{limit : 5}, (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 5
          done()

