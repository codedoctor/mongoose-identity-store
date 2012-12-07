async = require 'async'
_ = require 'underscore'
mongoose = require 'mongoose'
ObjectId = mongoose.Types.ObjectId

module.exports = class SampleUsers
  
  users: [ 
     {_id: new ObjectId('50bf85a816b4f6bff4000001'), username: 'test1', primaryEmail: 'test1@test.com', password: 'test1'}, 
     {_id: new ObjectId('50bf85a816b4f6bff4000002'), username: 'test2', primaryEmail: 'test2@test.com', password: 'test2'}, 
     {_id: new ObjectId('50bf85a816b4f6bff4000003'), username: 'test3', primaryEmail: 'test3@test.com', password: 'test3'}
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
