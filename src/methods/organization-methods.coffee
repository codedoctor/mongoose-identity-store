_ = require 'underscore-ext'
errors = require 'some-errors'

PageResult = require('../../../modules/paginator').PageResult

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId
bcrypt = require 'bcrypt'

{isObjectId} = require 'mongodb-objectid-helper'


###
Provides methods to interact with scotties.
###
module.exports = class OrganizationMethods
  CREATE_FIELDS = ['name']
  UPDATE_FIELDS = ['name', 'description', 'tags']

  ###
  Initializes a new instance of the @see ScottyMethods class.
  @param {Object} models A collection of models that can be used.
  ###
  constructor:(@models) ->
    throw new Error "models parameter is required" unless @models

  all:(offset = 0, count = 25, cb) =>
    @models.Organization.count (err, totalCount) =>
      return cb err if err
      @models.Organization.find {}, null, { skip: offset, limit: count}, (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, offset, count)

  ###
  Looks up a user by id.
  ###
  get: (id, cb = ->) =>
    id = new ObjectId id.toString()
    @models.Organization.findOne _id: id , (err, item) =>
      return cb err if err
      cb null, item

  getByName: (name, cb = ->) =>
    @models.Organization.findOne name: name , (err, item) =>
      return cb err if err
      cb null, item

  getByNameOrId: (nameOrId, cb = ->) =>
    if isObjectId(nameOrId)
      @get nameOrId, cb
    else
      @getByName nameOrId, cb

