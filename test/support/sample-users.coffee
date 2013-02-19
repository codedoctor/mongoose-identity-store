async = require 'async'
_ = require 'underscore'
mongoose = require 'mongoose'
ObjectId = mongoose.Types.ObjectId

module.exports = class SampleUsers
  
  users: [ 
     {_id: new ObjectId('50bf85a816b4f6bff4000001'), username: 'test1', primaryEmail: 'test1@test.com', password: 'test1', displayName: 'Test 1'} 
     {_id: new ObjectId('50bf85a816b4f6bff4000002'), username: 'test2', primaryEmail: 'test2@test.com', password: 'test2', displayName: 'Test 2'}
     {_id: new ObjectId('50bf85a816b4f6bff4000003'), username: 'test3', primaryEmail: 'test3@test.com', password: 'test3', displayName: 'Test 3'}
     {_id: new ObjectId('50bf85a816b4f6bff4000004'), username: 'alpha1', primaryEmail: 'alpha1@test.com', password: 'test3', displayName: 'Alpha 1'}
     {_id: new ObjectId('50bf85a816b4f6bff4000005'), username: 'alpha2', primaryEmail: 'alpha2@test.com', password: 'test3', displayName: 'Alpha 2'}
     {_id: new ObjectId('50bf85a816b4f6bff4000006'), username: 'alpha3', primaryEmail: 'alpha3@test.com', password: 'test3', displayName: 'Alpha 3'}
     {_id: new ObjectId('50bf85a816b4f6bff4000007'), username: 'alpha4', primaryEmail: 'alpha4@test.com', password: 'test3', displayName: 'Alpha 4'}
     {_id: new ObjectId('50bf85a816b4f6bff4000008'), username: 'alpha5', primaryEmail: 'alpha5@test.com', password: 'test3', displayName: 'Alpha 5'}
     {_id: new ObjectId('50bf85a816b4f6bff4000009'), username: 'alpha6', primaryEmail: 'alpha6@test.com', password: 'test3', displayName: 'Alpha 6'}
     {_id: new ObjectId('50bf85a816b4f6bff400000A'), username: 'alpha7', primaryEmail: 'alpha7@test.com', password: 'test3', displayName: 'Alpha 7'}
     {_id: new ObjectId('50bf85a816b4f6bff400000B'), username: 'alpha8', primaryEmail: 'alpha8@test.com', password: 'test3', displayName: 'Alpha 8'}
     {_id: new ObjectId('50bf85a816b4f6bff400000C'), username: 'alpha9', primaryEmail: 'alpha9@test.com', password: 'test3', displayName: 'Alpha 9'}
     {_id: new ObjectId('50bf85a816b4f6bff400000D'), username: 'alphaA', primaryEmail: 'alphaa@test.com', password: 'test3', displayName: 'Alpha 10'}
     {_id: new ObjectId('50bf85a816b4f6bff400000E'), username: 'alphaB', primaryEmail: 'alphab@test.com', password: 'test3', displayName: 'Alpha 11'}
    ]

  constructor: (@mongo) ->

  existingUserIds: (howMany = 3) =>
     _.first _.map(_.pluck( @users, '_id'), (x) -> x.toString() ), howMany

  nonExistingUserIds: (howMany = 3) => 
    _.first ['500f85a816b4f6bff4000000','510f85a816b4f6bff4000000','520f85a816b4f6bff4000000'], howMany

  setup: (cb) =>
    addOneUser = (user,done) =>
      @mongo.collection("users").save user,done 

    async.forEach @users, addOneUser, (err) =>
      cb err
