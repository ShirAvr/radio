_ = require "lodash"
Async = require "async"
Hoek = require "hoek"

class DurationManager # DurationHandler
  constructor: (@server, @db, @recordsName) ->
    Hoek.assert @server?, "server must be defined"
    Hoek.assert @db?, "db must be defined"
    Hoek.assert @recordsName?, "recordsName must be defined"

    @totalDuration = 0

  initialize: (callback) ->
    Async.series [
      (next) => @setCollectionName(next)
      (next) => @initCollection(next)
    ], callback

  listen: ->
    @server.on "response", (request) =>
      duration = @calculate request.info

      requestDuration =
        path: request.path
        method: request.method
        params: request.orig.params or request.params
        duration: duration

      if request.response._error?
        requestDuration.params.error = request.response._error 

      @totalDuration += duration

      @save requestDuration

  save: (requestDuration) ->
    @durationsCollection.insert requestDuration, (err) ->
      Hoek.assert !err, err

  print: ->
    @totalDuration /= 1000

    console.log()
    console.log "===================================="
    console.log "Record name: #{@recordsName}"
    console.log "Total duration: #{@totalDuration} [sec]"
    console.log()

  calculate: (info) ->
    startTime = new Date(info.received)
    doneTime = new Date(info.responded)
    doneTime - startTime

  setCollectionName: (callback) ->
    @db.listCollections().toArray (err, existCollections) =>
      return callback(err) if err?

      existCollectionsNames = _.map existCollections, "name"

      if "afterDurations" in existCollectionsNames
        err = new Error("afterDurations collection already exists")
        return callback(err)

      if "beforeDurations" in existCollectionsNames 
        @collectionName = "afterDurations" 
      else 
        @collectionName = "beforeDurations"

      callback()

  initCollection: (callback) ->
    @db.collection @collectionName, (err, durationsCollection) =>
      return callback(err) if err?

      @durationsCollection = durationsCollection
      callback()

module.exports = DurationManager
