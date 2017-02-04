_ = require "lodash"

exports.register = (server, options, next) ->
  
  [0...100].forEach (i) ->

    if 0 <= i < 20 
      method = "GET"
    else if 20 <= i < 40
      method = "POST"
    else if 40 <= i < 60
      method = "PUT"
    else if 60 <= i < 80
      method = "DELETE"
    else if 80 <= i < 100
      method = "PATCH"

    server.route
      method: method
      path: "/random#{i}"
      handler: (request, reply) ->
        console.log "START RANDOM#{i}"
        randomInMS = _.random(1,10) * 1000
        
        setTimeout -> 
          console.log "END RANDOM#{i}"

          if options.makeRandomErrors and _.random(1,10) is 1
            return reply(new Error()) 
          
          reply "#{randomInMS}ms"
        , randomInMS

  next()

exports.register.attributes =
  name: "random"
