mongoose = require 'mongoose'

module.exports =  OauthRedirectUriSchema = new mongoose.Schema
    uri:
      type: String
  , strict : true