mongoose = require 'mongoose'

module.exports = UserProfileSchema = new mongoose.Schema
  linkUrl:
    type : String
  linkIdentifier:
    type : String

  #twitter facebook myspace vimeo youtube etsy linkedin other
  provider:
    type : String
  #blog email social  site unknown
  linkType:
    type : String
  #primary user fanpage hashtag
  linkSubType:
    type : String
  caption:
    type : String
  isPublic:
    type: Boolean
    default: false
