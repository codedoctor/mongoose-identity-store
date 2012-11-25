_ = require 'underscore-ext'

Scope = require('../scope').Scope
PageResult = require('../../paginator').PageResult

###
Provides methods to interact with the scope store.
###
module.exports = class OauthScopeMethods

  ###
  A hash of scopes.
  ###
  loadedScopes : {}

  ###
  Initializes a new instance of the @see ScopeMethods class.
  @param {Object} models A collection of models to be used within the auth framework.
  @description
  The config object looks like this:
  ...
  scopes: [...]
  ...
  ###
  constructor:(@models, config) ->
    if config && config.scopes
      for scopeDefinition in config.scopes
        scope = new Scope(scopeDefinition)

        if scope.isValid()
          @loadedScopes[scope.name] = scope
        else
          console.log "Invalid scope in config - skipped - #{JSON.stringify(scopeDefinition)}"
          # Todo: Better logging, error handling

  all:(offset = 0, count = 25, cb) =>
    #TODO: when this is database driven, make sure you return the correct paging info
    cb null, new PageResult(@loadedScopes || [], _.keys(@loadedScopes).length, offset, count)

  get:(name, cb) =>
    cb null, @loadedScopes[name]


  # INTERNAL FUNCTIONS
  ###
  Returns an array of all scope names
  @sync
  ###
  allScopeNamesAsArray: () =>
    _.pluck(_.values(@loadedScopes), "name")

  getScope:(scope) =>
    @loadedScopes[scope]