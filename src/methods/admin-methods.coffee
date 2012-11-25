_ = require 'underscore-ext'
errors = require 'some-errors'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId
bcrypt = require 'bcrypt'
passgen = require 'passgen'


###
Provides methods to interact with scotties.
###
module.exports = class AdminMethods

  ###
  Initializes a new instance of the @see ScottyMethods class.
  @param {Object} models A collection of models that can be used.
  ###
  constructor:(@models, @users, @oauthApps, @oauthAuth) ->
    throw new Error "models parameter is required" unless @models
    throw new Error "users parameter is required" unless @users
    throw new Error "oauthApps parameter is required" unless @oauthApps
    throw new Error "oauthAuth parameter is required" unless @oauthAuth

  setup: (appName, username, email, password, clientId = null, secret = null, cb = ->) =>
    adminUser =
      username : username
      password : password
      email : email

    @users.create adminUser, (err, user) =>
      return cb err if err

      appData =
        name : appName
        clientId : clientId
        secret : secret

      @oauthApps.create appData, user.toActor(), (err, app) =>
        return cb err if err

        clientId = app.clients[0].clientId
        return cb new Error "Failed to create app client" unless clientId

        @oauthAuth.createOrReuseTokenForUserId user._id, clientId, null, null, null, (err, token) =>
          return cb err if err
          return cb new errors.NotFound(req.url) unless token # TODO: Different error

          token =
            accessToken : token.accessToken
            refreshToken : token.refreshToken
          cb null, app, user, token

