_ = require "lodash"
Async = require "async"
Hapi = require "hapi"
Hoek = require "hoek"
Mongo = require "mongodb"

server = new Hapi.Server()

db = undefined
internals = {}

internals.init = ->
	server.connection
    port: 4000
    routes: { cors: { origin: ["*"] } }

  server.route
    method: "GET"
    path: "/getData"
    handler: (request, reply) ->
      Async.parallel [
        (next) -> db.collection("beforeDurations", next)
        (next) -> db.collection("afterDurations", next)
      ], (err, results) ->
        return reply(err) if err?
        
        [internals.beforeCollection, internals.afterCollection] = results
        internals.getData(reply)

  server.start (err) =>
    Hoek.assert !err, err

    Mongo.MongoClient.connect "mongodb://127.0.0.1:27017/randomDb", (err, database) =>
      Hoek.assert !err, err
      
      db = database
      console.log "Server started at: #{server.info.uri}"

internals.getData = (callback) ->
  Async.parallel [
    internals.getDataForCollection.bind(null, internals.beforeCollection)
    internals.getDataForCollection.bind(null, internals.afterCollection)
  ], (err, results) ->
    return callback(err) if err?

    [before, after] = results
    return callback({ before, after })

internals.dataQuery = 
  [
    {
      $match:
        "params.error": { $exists: false }
    }
    { 
      $group:
        _id: { $concat: [ "$method", " ", "$path" ] }
        average: { $avg: "$duration" }
        rangeStart: { $min: "$duration" }
        rangeEnd: { $max: "$duration" }
    }
  ]

internals.errorsQuery =
  [
    {
      $match: 
        "params.error": { $exists: true }
    }
    { 
      $group:
        _id: { $concat: [ "$method", " ", "$path" ] }
        errorsCount: { $sum: 1 }
    }
  ]

internals.getDataForCollection = (collection, callback) ->
  Async.parallel [
    collection.aggregate.bind(collection, internals.dataQuery)
    collection.aggregate.bind(collection, internals.errorsQuery)
  ], (err, results) ->
    return callback(err) if err?

    [data, errors] = results
    dataObject = internals.makeDataObject(data, errors)
    callback(null, dataObject)

internals.makeDataObject = (data, errors) ->
  errors = _.keyBy(errors, "_id")

  data.map (val) ->
    route: val._id
    average: val.average
    range: [val.rangeStart, val.rangeEnd]
    errors: errors[val._id]?.errorsCount | 0

internals.init()