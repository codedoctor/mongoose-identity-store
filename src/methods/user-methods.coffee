_ = require 'underscore-ext'
errors = require 'some-errors'

PageResult = require('simple-paginator').PageResult

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId
bcrypt = require 'bcrypt'
passgen = require 'passgen'

{isObjectId} = require 'mongodb-objectid-helper'
require('date-utils') # NOTE DANGEROUS - FIND A BETTER METHOD SOMETIMES

###
Provides methods to interact with scotties.
###
module.exports = class UserMethods
  #CREATE_FIELDS = ['username']
  UPDATE_FIELDS_FULL = ['username', 'description', 'displayName', 'identities','primaryEmail'
    'profileLinks', 'userImages', 'selectedUserImage', 'emails', 'roles', 'data', 'resourceLimits','onboardingState',
    'title','location','needsInit']

  ###
  Initializes a new instance of the @see ScottyMethods class.
  @param {Object} models A collection of models that can be used.
  ###
  constructor:(@models) ->
    throw new Error "models parameter is required" unless @models


  all:(offset = 0, count = 25, cb) =>
    @models.User.count (err, totalCount) =>
      return cb err if err
      @models.User.find {}, null, { skip: offset, limit: count}, (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, offset, count)

  ###
  Retrieves users by passing a list of id's, which can be string or objectIds
  ###
  getByIds:(idList = [], cb) =>
    idList = _.map idList, (x) -> new ObjectId x.toString()

    @models.User.find({}).where('_id').in(idList).exec (err, items) =>
      return cb err if err
      items or= []

      cb null, new PageResult(items, items.length, 0, 99999999)

  ###
  Looks up a user by id.
  ###
  get: (id, cb = ->) =>
    id = new ObjectId id.toString()
    @models.User.findOne _id: id , (err, item) =>
      return cb err if err
      cb null, item

  getByName: (name, cb = ->) =>
    name = name.toLowerCase()
    @models.User.findOne username: name , (err, item) =>
      return cb err if err
      cb null, item

  getByPrimaryEmail: (email, cb = ->) =>
    email = email.toLowerCase()
    @models.User.findOne primaryEmail: email , (err, item) =>
      return cb err if err
      cb null, item

  getByNameOrId: (nameOrId, cb = ->) =>
    if isObjectId(nameOrId)
      @get nameOrId, cb
    else
      @getByName nameOrId, cb

  patch: (usernameOrId, obj = {}, actor, cb = ->) =>
    @getByNameOrId usernameOrId, (err, item) =>
      # CHECK ACCESS RIGHTS. If actor is not the creator
      return cb err if err
      return cb new errors.NotFound("/users/#{usernameOrId}") unless item

      _.extendFiltered item, UPDATE_FIELDS_FULL, obj
      item.save (err) =>
        return cb err if err

        if obj.password
          @setPassword usernameOrId,obj.password,actor, (err,item2) ->
            return cb err if err
            cb null, item
        else
          cb null, item

  delete: (usernameOrId, actor, cb = ->) =>
    @getByNameOrId usernameOrId, (err, item) =>
      # CHECK ACCESS RIGHTS. If actor is not the creator or in admin role
      return cb err if err
      return cb new errors.NotFound("/users/#{usernameOrId}") unless item

      return cb null if item.isDeleted

      item.isDeleted = true
      item.deletedAt = new Date()
      item.save (err) =>
        return cb err if err
        cb null, item

  destroy: (usernameOrId, actor, cb = ->) =>
    @getByNameOrId usernameOrId, (err, item) =>
      # CHECK ACCESS RIGHTS. If actor is not the creator or in admin role
      return cb err if err
      return cb new errors.NotFound("/users/#{usernameOrId}") unless item

      item.remove (err) =>
        return cb err if err
        cb null, item

  setPassword: (usernameOrId, password, actor, cb = ->) =>
    @getByNameOrId usernameOrId, (err, item) =>
      # CHECK ACCESS RIGHTS. If actor is not the creator or in admin role
      return cb err if err
      return cb new errors.NotFound("/users/#{usernameOrId}") unless item
      # TODO: Handle deleted
      #return cb null if item.isDeleted

      @hashPassword password, (err, hash) =>
        return cb err if err
        item.password = hash

        item.save (err) =>
          return cb err if err
          cb null, item

  ###
  Looks up a user by username or email.
  ###
  findUserByUsernameOrEmail: (usernameOrEmail, cb) =>
    usernameOrEmail = usernameOrEmail.toLowerCase()

    @models.User.findOne username: usernameOrEmail , (err, item) =>
      return cb err if err
      return cb(null, item) if item

      # Be smart, only try email if we have something that looks like an email.

      @models.User.findOne primaryEmail: usernameOrEmail , (err, item) =>
        return cb err if err
        cb(null, item)

  ###
  Looks up the user, if found validates against password.
  cb(err) in case of non password error.
  cb(null, user) in case of user not found, password not valid, or valid user
  ###
  validateUserByUsernameOrEmail: (usernameOrEmail, password, cb) =>
    usernameOrEmail = usernameOrEmail.toLowerCase()
    @findUserByUsernameOrEmail usernameOrEmail, (err, user) =>
      return cb err if err
      return cb(null, null) unless user
      bcrypt.compare password, user.password, (err, res) =>
        return cb err if err
        return cb(null, null) unless res
        cb(null, user)

  #verifyPassword: (hash)
  #bcrypt.compare("B4c0/\/", hash, function(err, res)

  hashPassword: (password, cb) =>
    bcrypt.genSalt 10, (err, salt) =>
      return cb err if err
      bcrypt.hash password, salt, (err, hash) =>
        return cb err if err
        cb(null, hash)

  ###
  Creates a new user.
  ###
  create: (objs = {}, cb) =>
    #_.extendFiltered data, CREATE_FIELDS, objs

    _.defaults objs, {username : null, primaryEmail : null , password : null}
    objs.primaryEmail = objs.email if objs.email && !objs.primaryEmail
    delete objs.email

    user = new @models.User objs
    user.emails = [objs.primaryEmail] if objs.primaryEmail

    ###
    var gravatar = require('gravatar');
    var url = gravatar.url('emerleite@gmail.com', {s: '200', r: 'pg', d: '404'});

    ###
    #email
    @hashPassword objs.password, (err, hash) =>
      return cb err if err
      user.password = hash

      user.save (err) =>
        return cb err if err

        cb(null, user)


  ###
  Gets or creates a user for a given provider/profile combination.
  @param {String} provider a provider string like "facebook" or "twitter".
  @param {String} v1 the key or access_token, depending on the type of provider
  @param {String} v2 the secret or refresh_token, depending on the type of provider
  @param {Object} profile The profile as defined here: http://passportjs.org/guide/user-profile.html
  ###
  getOrCreateUserFromProvider: (provider, v1, v2, profile, cb) =>
    return cb(new Error("An id parameter within profile is required.")) unless profile && profile.id

    #console.log "PROFILE #{JSON.stringify(profile)} ENDPROFILE" 

    identityQuery =
      'identities.provider': provider
      'identities.key': profile.id

    isNew = false
    @models.User.findOne identityQuery , (err, item) =>
      return cb err if err

      if item
        for identity in item.identities
          if identity.provider is provider
            identity.v1 = v1
            identity.v2 = v2
        item.save (err) =>
          return cb err if err
          cb null, item, isNew : isNew

      else
        isNew = true

        isUserNameValid = true

        pusername = profile.username || "fb#{profile.id}"

        @models.User.findOne username : pusername , (err,itemXX) =>
          return cb err if err
          isUserNameValid = !itemXX  #valid if it does not exist


          # PROFILE DATA:
          # profile.emails [{value,type}]
          # profile.name {familyName, givenName, middleName}
          # FB,Twitter: profile.username
          # FB: gender (male, female) => fb
          # FB: profileUrl
          # Twitter: .photos[0] -> URL

          # TWITTER MOCK:
          # {"id_str":"6253282","id":6253282,"profile_text_color":"437792","created_at":"Wed May 23 06:01:13 +0000 2007","contributors_enabled":true,"follow_request_sent":null,"lang":"en","listed_count":10154,"profile_sidebar_border_color":"0094C2","show_all_inline_media":false,"friends_count":34,"utc_offset":-28800,"location":"San Francisco, CA","name":"Twitter API","profile_background_tile":false,"profile_sidebar_fill_color":"a9d9f1","profile_image_url_https":"https:\/\/si0.twimg.com\/profile_images\/1438634086\/avatar_normal.png","protected":false,"geo_enabled":true,"following":null,"default_profile_image":false,"statuses_count":3252,"is_translator":false,"favourites_count":22,"profile_background_color":"e8f2f7",
          #  "description":"The Real Twitter API. I tweet about API changes, service issues and happily answer questions about Twitter and our API. Do not get an answer? It is on my website.",
          # "time_zone":"Pacific Time (US & Canada)","screen_name":"twitterapi",
          # "profile_background_image_url":"http:\/\/a0.twimg.com\/profile_background_images\/229557229\/twitterapi-bg.png",
          # "profile_image_url":"http:\/\/a0.twimg.com\/profile_images\/1438634086\/avatar_normal.png",
          # "profile_link_color":"0094C2",
          # "profile_background_image_url_https":"https:\/\/si0.twimg.com\/profile_background_images\/229557229\/twitterapi-bg.png",
          # "followers_count":931299,
          # "status":{"in_reply_to_status_id_str":null,"in_reply_to_user_id_str":null,
          #           "retweeted":false,"coordinates":null,"in_reply_to_screen_name":null,"created_at":"Tue Feb 14 23:39:43 +0000 2012","possibly_sensitive":false,"contributors":null,"in_reply_to_status_id":null,"entities":{"urls":[{"display_url":"tmblr.co\/ZgBqayGQi3ls","indices":[106,126],"expanded_url":"http:\/\/tmblr.co\/ZgBqayGQi3ls","url":"http:\/\/t.co\/cOzUfFNW"}],"user_mentions":[],"hashtags":[]},"geo":null,"in_reply_to_user_id":null,"place":null,"favorited":false,"truncated":false,"id_str":"169566520693882882","id":169566520693882882,"retweet_count":82,"text":"Photo Upload Issue - Some users may be experiencing an issue when uploading a photo. Our engineers are... http:\/\/t.co\/cOzUfFNW"},
          # "default_profile":false,
          # "notifications":null,
          # "url":"http:\/\/dev.twitter.com",
          # "profile_use_background_image":true,"verified":true}';
          # FACEBOOK MOCK
          ###
          { "_json" : { "email" : "martin@wawrusch.com",
      "favorite_athletes" : [ { "id" : "69025400418",
            "name" : "Kobe Bryant"
          },
          { "id" : "34778334225",
            "name" : "Kelly Slater"
          }
        ],
      "favorite_teams" : [ { "id" : "144917055340",
            "name" : "LA Lakers"
          } ],
      "first_name" : "Martin",
      "gender" : "male",
      "id" : "679841881",
      "last_name" : "Wawrusch",
      "link" : "http://www.facebook.com/martinw",
      "locale" : "en_US",
      "location" : { "id" : "109434625742337",
          "name" : "West Hollywood, California"
        },
      "name" : "Martin Wawrusch",
      "timezone" : -8,
      "updated_time" : "2012-10-31T18:05:42+0000",
      "username" : "martinw",
      "verified" : true
    },
  "_raw" : "{\"id\":\"679841881\",\"name\":\"Martin Wawrusch\",\"first_name\":\"Martin\",\"last_name\":\"Wawrusch\",\"link\":\"http:\\/\\/www.facebook.com\\/martinw\",\"username\":\"martinw\",\"location\":{\"id\":\"109434625742337\",\"name\":\"West Hollywood, California\"},\"favorite_teams\":[{\"id\":\"144917055340\",\"name\":\"LA Lakers\"}],\"favorite_athletes\":[{\"id\":\"69025400418\",\"name\":\"Kobe Bryant\"},{\"id\":\"34778334225\",\"name\":\"Kelly Slater\"}],\"gender\":\"male\",\"email\":\"martin\\u0040wawrusch.com\",\"timezone\":-8,\"locale\":\"en_US\",\"verified\":true,\"updated_time\":\"2012-10-31T18:05:42+0000\"}",
  "displayName" : "Martin Wawrusch",
  "emails" : [ { "value" : "martin@wawrusch.com" } ],
  "gender" : "male",
  "id" : "679841881",
  "name" : { "familyName" : "Wawrusch",
      "givenName" : "Martin"
    },
  "profileUrl" : "http://www.facebook.com/martinw",
  "provider" : "facebook",
  "username" : "martinw"
}

          ###
          # TODO: Check for existance here, try to keep username
          item = new @models.User
          item.username = (if isUserNameValid then pusername else pusername + passgen.create(4)).toLowerCase()
          item.displayName = profile.displayName || item.username || pusername
          item.data =  {} #profile._json
          item.description = profile.description || ''
          item.title = ""

          # Handling Images
          # Filter out all the images first
          images = []
          images = profile.photos if provider is 'twitter' && profile.photos && _.isArray(profile.photos)
          images.push "https://graph.facebook.com/#{profile.username || profile.id}/picture" if profile.username && provider is "facebook"

          # TODO: Add gravatar perhaps as well?
          for imageUrl in images
            item.userImages.push new @models.UserImage
              url : imageUrl
              # TODO: Add type here.

          # Twitter first
          if profile.profile_image_url && profile.profile_image_url.length > 5
            item.selectedUserImage = profile.profile_image_url
          else
            # Set the selected user image, be radical about it.
            item.selectedUserImage = images[0] if images.length > 0

          if provider is "facebook" && profile.profileUrl
            item.profileLinks.push new @models.UserProfile
              linkUrl : profile.profileUrl
              linkIdentifier: profile.id
              provider : provider
              linkType : 'social'
              linkSubType: 'primary'
              caption : "Facebook"
              isPublic: true

          if provider is "twitter" 
            item.profileLinks.push new @models.UserProfile
              linkUrl : "https://twitter.com/#{profile.username}"
              linkIdentifier: profile.username
              provider : provider
              linkType : 'social'
              linkSubType: 'primary'
              caption : "Twitter"
              isPublic: true

          emails = []
          if profile.emails && _.isArray(profile.emails)
            emails = _.map(profile.emails, (x) -> x.value)
          # emails
          for email in emails
            item.emails.push new @models.Email
              email : email.toLowerCase()
              isVerified : true # We assume so, because it comes from a social network
              sendNotifications : false # Dunno what this is good for.
          item.primaryEmail = item.emails[0].email.toLowerCase() if item.emails.length > 0

          item.location = profile._json?.location?.name
          item.needsInit = !profile.username || !item.primaryEmail || item.primaryEmail.toLowerCase().indexOf("facebook.com") > 0
          
          #item.needsInit = true

          item.gender = profile.gender
          item.timezone = profile._json?.timezone
          item.locale = profile._json?.locale
          item.verified = profile._json?.verified
          item.roles = ['user-needs-setup']

          newIdentity = new @models.UserIdentity
            provider: provider
            key: profile.id
            v1 : v1
            v2 : v2
            providerType: "oauth"
            username : item.username
            displayName : item.displayName
            profileImage : item.selectedUserImage
          item.identities.push newIdentity
            # More stuff
          item.save (err) =>
            return cb err if err
            cb null, item, isNew : isNew,newIdentity

  _usernameFromProfile: (profile) =>
    profile.username || ''

  _displayNameFromProfile: (profile) =>
    return profile.displayName if profile.displayName
    return "#{profile.name.givenName} #{profile.name.familyName}" if profile.name && profile.name.givenName && profile.name.familyName
    return profile.name.familyName if profile.name && profile.name.familyName
    profile.username

  _profileImageFromProfile: (profile) =>
    return "https://graph.facebook.com/#{profile.username}/picture" if profile.username && profile.provider is "facebook"
    return profile.photos[0].value if profile.provider is 'twitter' && profile.photos && _.isArray(profile.photos) && profile.photos.length > 0
    if profile.provider is 'instagram'
      try
        raw = JSON.parse profile._raw
        return raw.data.profile_picture
      catch e
        return null

    if profile.provider is 'foursquare'
      try
        raw = JSON.parse profile._raw
        return raw.response.user.photo
      catch e
        return null
    
    null


  ###
  Adds an identity to an existing user. In this version, it replaces an 
  existing provider of the same type.
  @param {String/ObjectId} userId the id of the user to add this identity to.
  @param {String} provider a provider string like "facebook" or "twitter".
  @param {String} v1 the key or access_token, depending on the type of provider
  @param {String} v2 the secret or refresh_token, depending on the type of provider
  @param {Object} profile The profile as defined here: http://passportjs.org/guide/user-profile.html
  ###
  addIdentityToUser: (userId,provider, v1, v2, profile, cb = ->) =>
    return cb new Error("A userId is required")  unless userId
    return cb new Error("A provider is required")  unless provider
    return cb new Error("A v1 is required")  unless v1
    return cb new Error("A profile is required")  unless profile
    return cb new Error("An id parameter within profile is required.")  unless profile && profile.id
    userId = new ObjectId(userId.toString())
    provider = provider.toLowerCase()

    @models.User.findOne _id: userId , (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/users/#{userId}") unless item

      existing = _.find item.identities, (x) -> x.provider is provider
      existing.remove() if existing

      newIdentity = new @models.UserIdentity
        provider: provider
        key: profile.id
        v1 : v1
        v2 : v2
        providerType: "oauth"
        username : @_usernameFromProfile(profile)
        displayName : @_displayNameFromProfile(profile)
        profileImage : @_profileImageFromProfile(profile)
      
      item.identities.push newIdentity
      item.save (err) =>
        return cb err if err
        cb null, item,newIdentity

  removeIdentityFromUser:(userId,identityId,cb = ->) =>
    return cb new Error("A userId is required")  unless userId
    return cb new Error("A identityId is required")  unless identityId
    userId = new ObjectId(userId.toString())
    identityId = new ObjectId(identityId.toString())

    @models.User.findOne _id: userId , (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/users/#{userId}") unless item

      existing = item.identities.id(identityId)
      existing.remove() if existing

      item.save (err) =>
        return cb err if err
        cb null, item

  addRoles:(userId,roles,cb = ->) =>
    return cb errors.UnprocessableEntity("userId") unless userId
    return cb errors.UnprocessableEntity("roles") unless roles && roles.length > 0
    userId = new ObjectId(userId.toString())

    @models.User.findOne _id: userId , (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/users/#{userId}") unless item
      item.roles = _.union(item.roles || [],roles)
      item.save (err) =>
        return cb err if err
        cb null,item.roles, item

  removeRoles:(userId,roles,cb = ->) =>
    return cb errors.UnprocessableEntity("userId") unless userId
    return cb errors.UnprocessableEntity("roles") unless roles && roles.length > 0
    userId = new ObjectId(userId.toString())

    @models.User.findOne _id: userId , (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/users/#{userId}") unless item
      item.roles = _.difference(item.roles || [],roles)
      item.save (err) =>
        return cb err if err
        cb null,item.roles, item

  resetPasswordTokenLength = 10

  resetPassword: (email,cb = ->) =>
    return cb new errors.UnprocessableEntity("email") unless email
    @getByPrimaryEmail email, (err,user) =>
      return cb err if err
      return cb new errors.NotFound("") unless user

      newToken = passgen.create(resetPasswordTokenLength) + user._id.toString() + passgen.create(resetPasswordTokenLength)
      user.resetPasswordToken =
        token: newToken
        validTill : (new Date()).add( days : 1)
      console.log "E"
      user.save (err) =>
        console.log "F"
        console.log "G"
        cb null,user,newToken

  #p0qEeKBoh25031326eefa65c0000000006TWlhZKbLjn
  resetPasswordToken: (token,password,cb = ->) =>
    return cb errors.UnprocessableEntity("token") unless token
    return cb errors.UnprocessableEntity("password") unless password

    userId = token.substr(resetPasswordTokenLength,token.length - 2 * resetPasswordTokenLength)
    userId = new ObjectId(userId)
    @hashPassword password, (err, hash) =>
      return cb err if err
      @models.User.findOne _id: userId , (err, user) =>
        return cb err if err
        return cb new errors.NotFound("/users/#{userId}") unless user
        return cb new errors.UnprocessableEntity('token') unless user.resetPasswordToken
        return cb new errors.UnprocessableEntity('token') unless (user.resetPasswordToken.token || '').toLowerCase() is token.toLowerCase()
        return cb new errors.UnprocessableEntity('validTill') unless user.resetPasswordToken.validTill && user.resetPasswordToken.validTill.isAfter(new Date())
        user.resetPasswordToken = null
        #user.markModified 'resetPasswordToken'
        user.password = hash
        user.save (err) =>
          return cb err if err
          cb null,user


  addEmail:(userId,email,isValidated,cb = ->) =>
    return cb errors.UnprocessableEntity("userId") unless userId
    return cb errors.UnprocessableEntity("email") unless email
    userId = new ObjectId(userId.toString())

    @models.User.findOne _id: userId , (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/users/#{userId}") unless item
      item.emails = _.union(item.emails || [],[email])
      item.save (err) =>
        return cb err if err
        cb null,item.emails, item

  removeEmail:(userId,email,cb = ->) =>
    return cb new errors.UnprocessableEntity("userId") unless userId
    return cb new errors.UnprocessableEntity("email") unless roles && roles.length > 0
    userId = new ObjectId(userId.toString())

    @models.User.findOne _id: userId , (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/users/#{userId}") unless item
      item.emails = _.difference(item.emails || [],[email])
      item.save (err) =>
        return cb err if err
        cb null,item.emails, item