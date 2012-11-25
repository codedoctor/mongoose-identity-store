_ = require 'underscore'
mongoose = require 'mongoose'
errors = require 'some-errors'

pluginAccessibleBy = require "mongoose-plugins-accessible-by"

pluginTimestamp = require "mongoose-plugins-timestamp"
pluginCreatedBy = require "mongoose-plugins-created-by"
pluginTagsSimple = require "mongoose-plugins-tags-simple"
pluginDeleteParanoid = require "mongoose-plugins-delete-paranoid"
pluginResourceLimits = require "mongoose-plugins-resource-limits"

OrganizationStatsType =
  accessCount:
    type : Number
    default : 0

OrganizationLinkType =
  target :
    type : String
  mimeType :
    type : String

module.exports = OrganizationSchema = new mongoose.Schema
    name:
      type : String
      unique: true
      trim : true
      required: true
      match: /.{2,40}/
    description :
      type : String
      trim: true
      default: ''
      match: /.{0,500}/
    stats:
      type: OrganizationStatsType
      default : () ->
        numberOfClones : 0
    profileLinks: # Links from external sources that link to this
      type: [OrganizationLinkType]
      default : () -> []
    data:
      type: mongoose.Schema.Types.Mixed
      default : () -> {}
  , strict: true

OrganizationSchema.plugin pluginTimestamp.timestamps
OrganizationSchema.plugin pluginCreatedBy.createdBy, isRequired : true
OrganizationSchema.plugin pluginTagsSimple.tagsSimple
OrganizationSchema.plugin pluginDeleteParanoid.deleteParanoid
OrganizationSchema.plugin pluginAccessibleBy.accessibleBy, defaultIsPublic : true
OrganizationSchema.plugin pluginResourceLimits.resourceLimits


OrganizationSchema.methods.toRest = (baseUrl, actor) ->
  res =
    url : "#{baseUrl}/#{@_id}"
    id : @_id
    name : @name
    description : @description
    stats : @stats || {}
    resourceLimits : @resourceLimits || {}
    profileLinks : @profileLinks || []
    data : @data || {}

    tags : @tags
    createdAt: @createdAt
    updatedAt: @updatedAt
    createdBy : @createdBy
    accessibleBy: @accessibleBy
    isDeleted : @isDeleted || false
    deletedAt : @deletedAt || null
  res


OrganizationSchema.statics.findOneValidate = (organizationId, actor, role, cb = ->) ->
  return cb new Error("organizationId is a required parameter") unless organizationId
  organizationId = organizationId.toString()
  Organization = @

  Organization.findOne _id : organizationId, (err, item) =>
    return cb err if err
    return cb new errors.NotFound("/organizations/#{organizationId}") unless item
    #console.log "AND THE WINNER IS: #{JSON.stringify(item.accessibleBy)}"
    return cb null, item if item.canPublicAccess(role)
    return cb null, item if actor && item.canActorAccess(actor, role)
    return cb null, item if actor && item.createdBy.actorId.toString() is actor.actorId.toString()

    cb new errors.AccessDenied("/organizations/#{organizationId}")


OrganizationSchema.statics.findOneValidateRead = (organizationId, actor, cb = ->) ->
  @findOneValidate organizationId, actor, "read", cb


OrganizationSchema.statics.findOneValidateWrite = (organizationId, actor, cb = ->) ->
  @findOneValidate organizationId, actor, "write", cb
