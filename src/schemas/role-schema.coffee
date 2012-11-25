mongoose = require 'mongoose'

module.exports = RoleSchema = new mongoose.Schema
  name:
    type : String
    unique: true
  description:
    type : String
  isInternal:
    type : Boolean
    default: false

