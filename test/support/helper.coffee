qs = require 'querystring'
_ = require 'underscore'
async = require 'async'
mongoose = require 'mongoose'
mongoskin = require 'mongoskin'
ObjectId = mongoose.Types.ObjectId

index = require '../../lib/index'
SampleUsers = require './sample-users'

class Helper
  database :  'mongodb://localhost/codedoctor-test'
  collections: ['oauthaccesstokens','oauthapps','oauthclients','organizations','users']

  cleanDatabase : (cb) =>
    cleanOne = (collection, cb) =>
      @mongo.collection(collection).remove {}, cb

    console.log "CLEANING Database #{@database}"
    async.forEach @collections, cleanOne, (err) =>
      console.log "ERROR: @{err}" if err
      console.log "CLEANED Database #{@database}"
      cb()

  start: (obj = {}, done = ->) =>
    _.defaults obj, 
      cleanDatabase : true

    mongoose.connect @database
    @mongo = mongoskin.db @database, safe:false
    @store = index.store()

    tasks = []

    if obj.cleanDatabase
      tasks.push (cb) =>
        @cleanDatabase(cb)

    async.series tasks, => done()


  stop: (done = ->) =>
    mongoose.disconnect (err) =>
      done()

  addSampleUsers: (cb) =>
    x = new SampleUsers(@mongo)
    x.setup(cb)
    x

  log: (obj) =>
    console.log ""
    console.log "+++++++++"
    console.log JSON.stringify(obj)
    console.log "---------"

  mongoCount: (name, cb) =>
    @mongo.collection(name).count cb


  mongoFindOne: (name, id, cb) =>
    id = new ObjectId id.toString()

    @mongo.collection(name).findOne _id : id , (err, item) =>
      return cb err if err
      # Leave stuff in here for logging later.
      cb null, item

  dumpOne: (name, id, cb) =>
    id = new ObjectId id.toString()
    @mongo.collection(name).findOne _id : id , (err, item) =>
      return cb err if err
      console.log ""
      console.log "========================== DUMPING #{name} FOR #{id}  =========================="
      console.log JSON.stringify(item)
      console.log "--------------------------------------------------------------------------------"
      cb null

  dumpCollection: (name, cb) =>
    console.log ""
    @mongo.collection(name).find({}).toArray (err, items) =>
        return cb err if err
        console.log "========================== DUMPING #{name} =========================="
        if items
          _.each items, (item) =>
            console.log JSON.stringify(item)
            console.log "-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
        else
          console.log "NO ITEMS"
        console.log "---------------------------------------------------------------------"
        cb null

module.exports = new Helper()
