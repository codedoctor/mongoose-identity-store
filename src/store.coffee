mongoose = require 'mongoose'
_ = require 'underscore'

UserSchema = require './schemas/user-schema'
OrganizationSchema = require './schemas/organization-schema'
UserIdentitySchema = require './schemas/user-identity-schema'
UserImageSchema = require './schemas/user-image-schema'
UserProfileSchema = require './schemas/user-profile-schema'
EmailSchema = require './schemas/email-schema'

OauthAccessGrantSchema = require './schemas/oauth-access-grant-schema'
OauthAccessTokenSchema = require './schemas/oauth-access-token-schema'
OauthAppSchema = require './schemas/oauth-app-schema'
OauthRedirectUriSchema = require './schemas/oauth-redirect-uri-schema'
OauthClientSchema = require './schemas/oauth-client-schema'

UserMethods = require './methods/user-methods'
OrganizationMethods = require './methods/organization-methods'
EntityMethods = require './methods/entity-methods'
OauthAppMethods = require './methods/oauth-app-methods'
OauthAuthMethods = require './methods/oauth-auth-methods'
OauthScopeMethods = require './methods/oauth-scope-methods'
AdminMethods = require './methods/admin-methods'

module.exports = class Store
  constructor: (@settings = {}) ->
    _.defaults @settings, 
                  autoIndex : true

    configOauthProvider = @settings.oauthProvider || { scopes: []}

    @schemas = [UserSchema,UserIdentitySchema,UserImageSchema,UserProfileSchema,EmailSchema,
                OrganizationSchema,OauthAccessGrantSchema,OauthAccessTokenSchema,OauthAppSchema,
                OauthRedirectUriSchema,OauthClientSchema]

    for schema in @schemas
      schema.set 'autoIndex', @settings.autoIndex


    @models =
      User : mongoose.model "User", UserSchema
      UserIdentity: mongoose.model "UserIdentity", UserIdentitySchema
      UserImage: mongoose.model "UserImage", UserImageSchema
      UserProfile: mongoose.model "UserProfile", UserProfileSchema
      Email: mongoose.model "Email", EmailSchema
      Organization : mongoose.model "Organization", OrganizationSchema
      OauthAccessGrant : mongoose.model "OAuthAccessGrant", OauthAccessGrantSchema
      OauthAccessToken : mongoose.model "OauthAccessToken", OauthAccessTokenSchema
      OauthApp : mongoose.model "OauthApp", OauthAppSchema
      OauthRedirectUri : mongoose.model "OauthRedirectUri", OauthRedirectUriSchema
      OauthClient : mongoose.model "OauthClient", OauthClientSchema

    @users = new UserMethods @models
    @organizations = new OrganizationMethods @models
    @entities = new EntityMethods @models
    @oauthScopes =  new OauthScopeMethods @models , configOauthProvider
    @oauthApps = new OauthAppMethods @models, @oauthScopes
    @oauthAuth = new OauthAuthMethods @models
    @admin = new AdminMethods @models, @users, @oauthApps, @oauthAuth
