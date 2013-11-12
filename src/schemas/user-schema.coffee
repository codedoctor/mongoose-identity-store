mongoose = require 'mongoose'
_ = require 'underscore'

pluginTimestamp = require "mongoose-plugins-timestamp"
pluginDeleteParanoid = require "mongoose-plugins-delete-paranoid"
pluginResourceLimits = require "mongoose-plugins-resource-limits"

EmailSchema = require './email-schema'
UserIdentitySchema = require './user-identity-schema'
UserProfileSchema = require './user-profile-schema'
UserImageSchema = require './user-image-schema'

###
  Perhaps we should talk about identities, not users
  Anonymous | Cookie
  Local: Username
  Oauth: Twitter : Identifier
###


module.exports = UserSchema = new mongoose.Schema
  username:
    type : String

  displayName:
    type : String

  password:
    type : String

  identities:
    type: [UserIdentitySchema]
    default: []

  profileLinks:
    type: [UserProfileSchema]
    default: []

  userImages:
    type: [UserImageSchema]
    default: []

  selectedUserImage:
    type: String

  primaryEmail: 
    type: String

  emails:
    type: [exports.EmailSchema]
    default: []

  roles:
    type: [String]
    default: []

  onboardingState:  
    type: String
    default: null

  needsInit:
    type: Boolean
    default : false

  data:
    type: mongoose.Schema.Types.Mixed
    default : () -> {}

  stats:
    type: mongoose.Schema.Types.Mixed
    default :() -> {}

  description :
    type : String
    trim: true
    default: ''
    match: /.{0,500}/

  gender: 
    type: String
    default: ''
  timezone:
    type: Number
    default: 0
  locale:
    type: String
    default: 'en_us'
  verified:
    type: Boolean
    default:false
  title: 
    type: String

  location: 
    type: String

  resetPasswordToken:
    type: 
      token : String
      validTill : Date
 , strict: true

UserSchema.path('username').index({ unique: true, sparse: false})
UserSchema.path('primaryEmail').index({ unique: true, sparse: true })

UserSchema.plugin pluginTimestamp.timestamps
UserSchema.plugin pluginDeleteParanoid.deleteParanoid
UserSchema.plugin pluginResourceLimits.resourceLimits

UserSchema.pre 'save', (next) ->
  @username = @username.toLowerCase() if @username
  @primaryEmail = @primaryEmail.toLowerCase() if @primaryEmail
  next()

UserSchema.methods.toActor = () ->
  actor =
    actorId : @_id
  actor

UserSchema.methods.toRest = (baseUrl, actor) ->
  localUrl = "#{baseUrl}/#{@_id}"
  res =
    url : localUrl
    id : @_id
    username : @username
    displayName : @displayName
    description : @description

    identities : _.map(@identities, (x) -> x.toRest("#{localUrl}/identities",actor)) || []
    profileLinks : @profileLinks || []
    userImages : @userImages || []
    selectedUserImage :@selectedUserImage
    emails :@emails || []
    roles :@roles || []
    data : @data || {}

    stats : @stats || {}
    resourceLimits : @resourceLimits || {}

    createdAt: @createdAt
    updatedAt: @updatedAt
    createdBy : @createdBy
    isDeleted : @isDeleted || false
    deletedAt : @deletedAt || null
    onboardingState : @onboardingState
    primaryEmail : @primaryEmail
    resetPasswordToken : @resetPasswordToken

    title:@title
    location: @location
    needsInit : @needsInit

    gender: @gender
    timezone: @timezone
    locale: @locale
    verified: @verified

  res
