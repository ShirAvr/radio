Hoek = require "hoek"

Radio = require "./radio"


exports.register = (plugin, options, next) ->
  action = options.action or "none"
  return next() if action is "none"

  radio = new Radio plugin.servers[0], options


  radio.initialize (err) ->
    Hoek.assert !err, err

  return next()


exports.register.attributes =
  pkg: require "../package.json"