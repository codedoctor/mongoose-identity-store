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
RoleSchema = require './schemas/role-schema'

UserMethods = require './methods/user-methods'
OrganizationMethods = require './methods/organization-methods'
EntityMethods = require './methods/entity-methods'
OauthAppMethods = require './methods/oauth-app-methods'
OauthAuthMethods = require './methods/oauth-auth-methods'
OauthScopeMethods = require './methods/oauth-scope-methods'
AdminMethods = require './methods/admin-methods'
RoleMethods = require './methods/role-methods'

module.exports = class Store
  constructor: (@settings = {}) ->
    _.defaults @settings, 
                  autoIndex : true

    configOauthProvider = @settings.oauthProvider || { scopes: []}

    @schemas = [UserSchema,UserIdentitySchema,UserImageSchema,UserProfileSchema,EmailSchema,
                OrganizationSchema,OauthAccessGrantSchema,OauthAccessTokenSchema,OauthAppSchema,
                OauthRedirectUriSchema,OauthClientSchema,RoleSchema]

    for schema in @schemas
      schema.set 'autoIndex', @settings.autoIndex

    m = mongoose
    m = @settings.connection if @settings.connection

    @models =
      User : m.model "User", UserSchema
      Role : m.model "Role", RoleSchema
      UserIdentity: m.model "UserIdentity", UserIdentitySchema
      UserImage: m.model "UserImage", UserImageSchema
      UserProfile: m.model "UserProfile", UserProfileSchema
      Email: m.model "Email", EmailSchema
      Organization : m.model "Organization", OrganizationSchema
      OauthAccessGrant : m.model "OAuthAccessGrant", OauthAccessGrantSchema
      OauthAccessToken : m.model "OauthAccessToken", OauthAccessTokenSchema
      OauthApp : m.model "OauthApp", OauthAppSchema
      OauthRedirectUri : m.model "OauthRedirectUri", OauthRedirectUriSchema
      OauthClient : m.model "OauthClient", OauthClientSchema

    @users = new UserMethods @models
    @organizations = new OrganizationMethods @models
    @entities = new EntityMethods @models
    @oauthScopes =  new OauthScopeMethods @models , configOauthProvider
    @oauthApps = new OauthAppMethods @models, @oauthScopes
    @oauthAuth = new OauthAuthMethods @models
    @admin = new AdminMethods @models, @users, @oauthApps, @oauthAuth
    @roles = new RoleMethods @models

