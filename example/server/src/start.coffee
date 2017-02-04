Hapi = require "hapi"
Hoek = require "hoek"
Radio = require "../node_modules/radio/lib/index.js"
Random = require "./random"

server = new Hapi.Server()

internals = {}

Radio.options =
  action: "none" # = "record" or "replay" or "none"
  dbUrl: "mongodb://127.0.0.1:27017/randomDb"
  recordsName: "random"

Random.options =
  makeRandomErrors: false # should be true only on "replay" mode

internals.init = ->
	server.connection  
    port: 3000
    routes: { cors: { origin: ["*"] } }

  server.register [Radio, Random], (err) ->
    Hoek.assert !err, err

    server.start (err) ->
	    Hoek.assert !err, err
	    console.log "Server started at: #{server.info.uri}"

internals.init()