_ = require 'underscore'

class exports.Scope
  constructor: (definition = {}) ->
    _.extend @, definition

  isValid: () =>
    @name && @name.length > 0

  toRest:(baseUrl, actor) =>
    res =
      slug : @name
      name : @name
      description : @description || ''
      developerDescription : @developerDescription || ''
      roles : @roles || []

    res.url = "#{baseUrl}/#{@name}"
    res