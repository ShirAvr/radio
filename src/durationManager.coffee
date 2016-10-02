Hoek = reqire "hoek"

class DurationManager # DurationHandler
  subCollectionName: "Durations"

  constructor: (@server, @db, @recordsName) ->
    Hoek.assert @server?, "server must be defined"
    Hoek.assert @db?, "db must be defined"
    hoek.assert @recordsName?, "recordsName must be defined"

    @totalDuration = 0

    @collectionName = "#{@recordsName}#{subCollectionName}"

  initialize: (callback) ->
    @initCollection (err, durationsCollection) =>
      return callback(err) if err?

      @durationsCollection = durationsCollection

      callback()

  listen: ->
    @server.on "response", (request) =>
      duration = @calculate request._logger

      requestDuration =
        path: request.path
        method: request.method
        params: request.orig.params or request.params
        duration: duration

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

  calculate: (logger) ->
    startTime = new Date(logger[0].timestamp)
    doneTime = new Date()
    doneTime - startTime

  initCollection: (callback) ->
    @db.collection @collectionName, (err, durationsCollection) ->
      return callback(err) if err?

      durationsCollection.remove {}, callback

module.exports = DurationManager
