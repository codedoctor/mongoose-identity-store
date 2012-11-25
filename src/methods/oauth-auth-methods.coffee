_ = require 'underscore-ext'

PageResult = require('simple-paginator').PageResult
passgen = require('passgen')


###
Provides methods to interact with the auth store.
###
module.exports = class OauthAuthMethods

  TENYEARSINSECONDS =  60 * 60 * 24 * 365 * 10
  TENMINUTESINSECONDS = 60 * 10

  ###
  Returns the current date + seconds
  @param {Number} seconds The seconds, or if null then roughly 10 years is assumed.
  ###
  currentDateAndSeconds:(seconds = TENYEARSINSECONDS) =>
    now = new Date()
    now.setSeconds(now.getSeconds() + seconds)
    now

  ###
  Initializes a new instance of the @see AuthMethods class.
  @param {Object} models A collection of models to be used within the auth framework.
  ###
  constructor:(@models) ->
    throw new Error("models parameter is required") unless @models


  ###
  Retrieves an app for a key. This ONLY retrieves active keys
  @param {string} appKey the application key to retrieve the app for.
  ###
  appForClientId:(clientId, cb) =>
    return cb new Error("clientId parameter missing in appForClientId") unless clientId

    @models.OauthApp.findOne 'clients.clientId' : clientId, (err, item) =>
      return cb err if err
      # TODO: Mutliple keys, check if revoked
      cb(null, item)

  ###
  Somehow validates a token. A valid token exists, has not been revoked yet,
  has an expiration higher than now.
  isClientValid can be checked for tighter security.
  ###
  validate: (token, clientId, cb) =>
    # TODO: APP/CLient shit
    @models.OauthAccessToken.findOne _id : token, (err, item) =>
      return cb err  if err

      #console.log "XXX #{JSON.stringify(item)}"

      return cb null, isValid : false unless item

      cb null,
        isValid : !item.revoked
        isClientValid: true #!!(clientId.toString() is item.client_id.toString())
        actor:
          actorId: item.identityUserId # make sure this is the id
        clientId : clientId # item.client_id.toString()
        scopes : item.scope || []
        expiresIn : 10000 #expires_at - calculate seconds till expiration

  ###
  Creates a new access grant.
  @param {String || ObjectId} appId the mongoose app id.
  @param {String || ObjectId} userId the mongoose user id
  @param {String} redirectUrl the requested redirect_uri. This must be later matched when issuing an access token.
  @param {String[]} scope an array of strings, with one or more elements, specifying the scope that should be granted.
  @param {String} realm an optional realm for which this access grant is for.
  @param {Callback} cb the callback that will be invoked, with err and the mongoose AccessGrant model.
  ###
  createAccessGrant: (appId, userId, redirectUrl, scope, realm = null, cb) =>
    return cb new Error("userId parameter missing in createAccessGrant") unless userId
    return cb new Error("appId parameter missing in createAccessGrant") unless appId
    return cb new Error("redirectUrl parameter missing in createAccessGrant") unless redirectUrl
    return cb new Error("scope parameter missing in createAccessGrant") unless scope && scope.length > 0

    accessGrant = new @models.OauthAccessGrant
      appId : appId
      identityUserId: userId
      realm : realm
      redirectUrl : redirectUrl
      scope : scope
      expiresAt : @currentDateAndSeconds(TENMINUTESINSECONDS)

    accessGrant.save (err) =>
      return cb err if err
      cb null, accessGrant

  ###
  Creates a token for a user/app/realm
  ###
  createOrReuseTokenForUserId: (userId, clientId, realm, scope , expiresIn, cb) =>
    @createTokenForUserId userId, clientId, realm, scope, expiresIn, cb


  ###
  Creates a token for a user/app/realm
  ###
  createTokenForUserId: (userId, clientId, realm =  null, scope = null, expiresIn = null, cb) =>
    #console.log "Looking up App for ClientId: #{clientId}"
    @appForClientId clientId, (err, app) =>
      return cb err if err
      return cb new Error("Could not find app for clientId #{clientId}") unless app

      token = new @models.OauthAccessToken
        appId: app._id
        identityUserId: userId
        realm: realm
        expiresAt: @currentDateAndSeconds(expiresIn || 3600) # WRONG OR
        scope: if scope && scope.length > 0 then scope else app.scopes

      token.save (err) =>
          return cb err if err
          cb(null, token)

  ###
  Takes a code and exchanges it for an access token
  @param {String} code the authorization_code to exchange into an access token
  ###
  exchangeAuthorizationCodeForAccessToken: (code, cb) =>
    @models.OauthAccessGrant.findOne _id: code, (err, accessGrant) =>
      return cb err if err
      return cb(new Error("NOT FOUND")) unless accessGrant

      # TODO: CHECK VALIDITY

      token = new @models.OauthAccessToken
        appId: accessGrant.appId
        identityUserId: accessGrant.userId
        realm: accessGrant.realm
        expiresAt: @currentDateAndSeconds(3600) # PROBABLY TOTALLY WRONG
        scope: accessGrant.scope

      token.save (err) =>
          return cb err if err

          accessGrant.revokedAt =  new Date()
          accessGrant.accessToken = token._id
          accessGrant.save (err) =>
            return cb err if err

            cb(null, token)

  ###
  Takes a code and exchanges it for an access token
  @param {String} refreshToken the refresh_token to exchange into an access token
  ###
  exchangeRefreshTokenForAccessToken: (refreshToken, cb) =>
    @models.OauthAccessToken.findOne refreshToken: refreshToken, (err, token) =>
      return cb err if err
      return cb(new Error("NOT FOUND 2")) unless token # DO some shit

      token.refreshToken = null
      # MAKE SURE THIS TOKEN IS EXPIRED

      token.save (err) =>
        return cb err if err

        newToken = new @models.OauthAccessToken
          appId: token.appId
          identityUserId: token.userId
          realm: token.realm
          expiresAt: @currentDateAndSeconds(3600) # PROBABLY TOTALLY WRONG
          scope: token.scope

        newToken.save (err) =>
          return cb err if err
          cb(null, newToken)


  #issueAccessToken: (userId, clientId, clientSecret = null, realm = null, scope = null, expiresIn = null, cb) =>

  ###
  getUserIdForAccessTokenString: (accessTokenString, cb) =>
      cb(null)



  listAccessTokens: (cb) =>
    cb(null)
  ###
