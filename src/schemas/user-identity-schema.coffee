mongoose = require 'mongoose'
_ = require 'underscore'

module.exports = UserIdentitySchema = new mongoose.Schema
  provider:
    type : String
  key:
    type : String
  v1:
    type : String
  v2:
    type : String
  providerType:
    type: String
    default: "oauth"
  profileImage:
    type: String
    default: ''
  username:
    type: String
    default: ''
  displayName:
    type: String
    default: ''


UserIdentitySchema.methods.toRest = (baseUrl, actor) ->
  res =
    url : "#{baseUrl}/#{@_id}"
    id : @_id
    provider : @provider
    key : @key
    v1 : @v1
    v2 : @v2
    providerType : @providerType
    username : @username
    displayName : @displayName
    profileImage : @profileImage
  res

