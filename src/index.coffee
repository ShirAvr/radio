Hoek = require "hoek"

Radio = require "./radio"

exports.register = (server, options, next) ->
  action = options.action or "none"
  return next() if action is "none"

  radio = new Radio server, options

  radio.initialize (err) ->
    Hoek.assert !err, err

  return next()

exports.register.attributes =
  pkg: require "../package.json"