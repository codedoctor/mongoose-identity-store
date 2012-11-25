_ = require 'underscore-ext'
errors = require 'some-errors'

PageResult = require('simple-paginator').PageResult

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId
bcrypt = require 'bcrypt'

{isObjectId} = require 'mongodb-objectid-helper'

###
Provides methods to interact with scotties.
###
module.exports = class EntityMethods
  ###
  Initializes a new instance of the @see ScottyMethods class.
  @param {Object} models A collection of models that can be used.
  ###
  constructor:(@models) ->
    throw new Error "models parameter is required" unless @models

  ###
  Looks up a user or organization by id. Users are first.
  ###
  get: (id, cb = ->) =>
    id = new ObjectId id.toString()
    @models.User.findOne _id: id , (err, item) =>
      return cb err if err
      return cb null, item if item
      @models.Organization.findOne _id: id , (err, item) =>
        return cb err if err
        cb null, item


  getByName: (name, cb = ->) =>
      @models.User.findOne username: name , (err, item) =>
        return cb err if err
        return cb null, item if item
        @models.Organization.findOne name: name , (err, item) =>
          return cb err if err
          cb null, item

  getByNameOrId: (nameOrId, cb = ->) =>
    if isObjectId(nameOrId)
      @get nameOrId, cb
    else
      @getByName nameOrId, cb

