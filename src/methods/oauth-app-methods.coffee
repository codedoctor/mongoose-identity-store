_ = require 'underscore-ext'
errors = require 'some-errors'

PageResult = require('simple-paginator').PageResult

module.exports = class OauthAppMethods
  KEY_LENGTH = 20
  SECRET_LENGTH = 40
  APP_CREATE_FIELDS =  ['name', 'websiteUrl', 'imageUrl', 'notes', 'tosAcceptanceDate', 'scope', 'description', 'acceptTermsOfService', 'isPublished', 'organizationName', 'organizationUrl']

  constructor:(@models, @scopeMethods) ->
    throw new Error("models parameter is required") unless @models
    throw new Error("scopeMethods parameter is required") unless @scopeMethods

  create:(objs = {}, actor, cb) =>
    throw new Error("actor parameter is required") unless actor

    optionalClientId = objs.clientId
    optionalSecret = objs.secret

    data = {}
    _.extendFiltered data, APP_CREATE_FIELDS, objs
    data.createdBy = actor

    data.scopes = @scopeMethods.allScopeNamesAsArray()
    model = new @models.OauthApp(data)

    if objs.callbackUrl
      model.redirectUrls.push new @models.OauthRedirectUri(uri: objs.callbackUrl)

    oAuthClient = new @models.OauthClient()
    oAuthClient.clientId = optionalClientId if optionalClientId
    oAuthClient.secret = optionalSecret if optionalSecret

    model.clients.push oAuthClient
    model.save (err) =>
      return cb err if err
      cb(null, model)


  all:(offset = 0, count = 25, cb) =>
    @models.OauthApp.count (err, totalCount) =>
      return cb err if err
      @models.OauthApp.find {}, null, { skip: offset, limit: count}, (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, offset, count)

  getAppsForUser:(owningUserId, offset = 0, count = 25, cb) =>
    owningUserId = owningUserId.toString()
    @models.OauthApp.find( 'createdBy.actorId' : owningUserId).count (err, totalCount) =>
      return cb err if err
      @models.OauthApp.find 'createdBy.actorId' : owningUserId, null, { skip: offset, limit: count}, (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, offset, count)

  getApp: (oauthAppId, cb) =>
    @models.OauthApp.findOne _id : oauthAppId, (err, item) =>
      return cb err if err
      cb(null, item)

  delete: (oauthAppId, cb) =>
    @deleteApp(oauthAppId, cb)

  deleteApp: (oauthAppId, cb) =>
    @models.OauthApp.remove _id : oauthAppId, (err) =>
      return cb err if err
      cb(null)

  resetAppKeys: (oauthAppId, cb) =>
    @models.OauthApp.findOne _id : oauthAppId, (err, item) =>
      return cb err if err

      item.clients[0].clientId =passgen.create(KEY_LENGTH)
      item.clients[0].secret = passgen.create(SECRET_LENGTH)

      item.save (err) =>
        return cb err if err
        cb(null, item)

  update: (oauthAppId, data = {}, cb) =>
    @updateApp(oauthAppId, data, cb)


  updateApp: (oauthAppId, data = {}, cb) =>
    @models.OauthApp.findOne _id : oauthAppId, (err, item) =>
      return cb err if err

      # TODO FILTER, VALIDATION, IMAGES
      _.extend item, data

      item.save (err) =>
        return cb err if err
        cb(null, item)
