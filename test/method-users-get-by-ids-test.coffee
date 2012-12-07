should = require 'should'
helper = require './support/helper'
_ = require 'underscore'
mongoose = require 'mongoose'
ObjectId = mongoose.Types.ObjectId

sampleUsers = null

describe 'WHEN working with store.users.getByIds', ->

  before (done) ->
    helper.start null, done

  after (done) ->
    helper.stop done

  it 'should exist', ->
    should.exist helper.store.users

  describe 'WHEN running against an empty database', ->
    describe 'WHEN invoking getByIds', ->
      it 'WITH empty parameters IT should return an empty list', (done) ->
        helper.store.users.getByIds [], (err,result) ->
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
    describe 'WHEN invoking getByIds', ->
      it 'WITH empty parameters IT should return an empty list', (done) ->
        helper.store.users.getByIds [], (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 0
          done()

      it 'WITH non existing object ids  IT should return an empty list', (done) ->
        helper.store.users.getByIds sampleUsers.nonExistingUserIds(3), (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 0
          done()

      it 'WITH partially non existing object ids  IT should return an only the matches', (done) ->
        nonExisting = sampleUsers.nonExistingUserIds(3)
        existing = sampleUsers.existingUserIds(3)
        
        #helper.log _.union(nonExisting,existing)

        helper.store.users.getByIds _.union(nonExisting,existing), (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 3
          done()

      it 'WITH valid duplicates IT should only return one', (done) ->
        existing = sampleUsers.existingUserIds(3)
        existing.push existing[0]

        helper.store.users.getByIds existing, (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 3
          done()

      it 'WITH valid object ids (not strings) IT should return those', (done) ->
        existing = sampleUsers.existingUserIds(3)
        existing = _.map existing, (x) => new ObjectId(x)

        helper.store.users.getByIds existing, (err,result) ->
          return done err if err
          should.exist.result
          result.should.have.property "items"
          result.items.should.have.lengthOf 3
          done()

      ###
      NOTE: WE NEED TO ADD THIS, but no time today.
      it 'WITH invalid object ids it should return an argument error', (done) ->
        invalid = ['hallo','frank']

        helper.store.users.getByIds invalid, (err,result) ->
          should.exist err
          # TODO: Ensure that this is the right kind of error
          done()
      ###