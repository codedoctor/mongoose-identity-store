_ = require 'underscore-ext'
PageResult = require('simple-paginator').PageResult
errors = require 'some-errors'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId


module.exports = class RoleMethods
  CREATE_FIELDS = ['_id','name','description','isInternal']
  UPDATE_FIELDS = ['name','description','isInternal']

  constructor:(@models) ->

  all: (options = {},cb = ->) =>

    @models.Role.count  {}, (err, totalCount) =>
      return cb err if err

      options.offset or= 0
      options.count or= 1000

      query = @models.Role.find({})
      query.sort('name')
      query.select options.select if options.select && options.select.length > 0

      query.setOptions { skip: options.offset, limit: options.count}
      query.exec (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, options.offset, options.count)


  ###
  Create a new processDefinition
  ###
  create:(objs = {}, options = {}, cb = ->) =>
    data = {}

    _.extendFiltered data, CREATE_FIELDS, objs

    model = new @models.Role(data)
    model.save (err) =>
      return cb err if err
      cb(null, model,true)

  ###
  Retrieve a single processDefinition-item through it's id
  ###
  get: (roleId,options = {}, cb = ->) =>
    @models.Role.findOne _id : roleId, (err,item) =>
      return cb err if err
      cb null, item

  patch: (roleId, obj = {}, options={}, cb = ->) =>
    @models.Role.findOne _id : roleId, (err,item) =>
      return cb err if err
      return cb new errors.NotFound("#{roleId}") unless item

      _.extendFiltered item, UPDATE_FIELDS, obj
      item.save (err) =>
        return cb err if err
        cb null, item

  destroy: (roleId, options = {}, cb = ->) =>
    @models.Role.findOne _id : roleId, (err,item) =>
      return cb err if err
      return cb null unless item

      item.remove (err) =>
        return cb err if err
        cb null

