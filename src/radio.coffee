_ = require "lodash"
Async = require "async"
Hoek = require "hoek"
Mongo = require "mongodb"
Request = require "request"
Streamifier = require "streamifier"
Url = require "url"

DurationManager = require "./durationManager"
Record = require "./record"

class Radio

  constructor: (@server, @options) ->
    Hoek.assert @server?, "server must be defined"
    Hoek.assert @options.dbUrl?, "dbUrl must be defined"
    Hoek.assert @options.recordsName?, "recordsName must be defined"
    Hoek.assert _.includes(["record", "replay", "none"], @options.action), 
      "you must specify one of these actions: [record, replay, none]"

  initialize: (callback) ->
    @openDb (err, @db, @collection) =>
      return callback(err) if err?
      @durationManager = new DurationManager @server, @db, @options.recordsName

      @durationManager.initialize (err) =>
        return callback(err) if err?

        switch @options.action
          when "record" then @record()
          when "replay" then @replay()

        callback()

  record: ->
    records = {}
    startRecord = new Date()

    @server.on "request-internal", (request, events, tags) =>
      return if request.method == "options"

      id = request.id
      record = records[id]

      if tags.received?

        timestamp = new Date(events.timestamp)
        delay = timestamp - startRecord

        recordInfo =
          path: request.path
          method: request.method
          headers: request.headers
          delay: delay
          query: JSON.stringify(request.query).toString()

        record = records[id] = new Record(request.id, recordInfo)
        
      # Should define payload only if undefined yet. We want to save the first
      # time payload was defined (the event called multiple times per request)

      record.payload ?= _.cloneDeep(request.orig?.payload or request.payload) if request.payload?
      record.params ?= _.cloneDeep(request.orig?.params or request.params) if request.params?

      @getChunkedData(request.raw.req, record) if tags.auth? and @streamRequest(request)

      if tags.response?
        delete records[id]
        record.save @recordsCollection, (err) ->
          Hoek.assert !err, err

  replay: ->
    @recordsCollection.find().toArray (err, records) =>
      @durationManager.listen()

      Async.each records, (record, next) =>
        @replayByDelay record, record.delay, next

      , (err) =>
        Hoek.assert !err, err
        @durationManager.print()

  replayByDelay: (record, delay, callback) ->
    _.delay @request.bind(this, record, callback), delay

  request: (record, callback) ->
    routeUrl = Url.resolve @server.info.uri, record.path

    headers =
      authorization: record.headers?.authorization # TODO: add 'if-modified-since' value

    request = 
      method: record.method
      headers: headers
      params: record.params
      body: JSON.stringify(record.payload)
      url: routeUrl
      timeout: @options.timeout

    request.qs = JSON.parse(record.query) if record.query?

    stream = @createReadStream(request, record.payload.buffer) if @isStreamRequest(record)

    req = Request request, (err, res, body) ->
      err ?= body if res?.statusCode isnt 200
      console.log err if err?
      return callback() unless stream?

    stream.pipe(req).on "end", callback if stream?

  isStreamRequest: (request) ->
    request.headers?["transfer-encoding"] is "chunked"

  getChunkedData: (stream, record) ->
    # It requires a uniqe treatment for a stream object, in order to get all the chunked data.
    # We ovveride the 'push' function of the stream buffer array, and whenever that function is
    # called, it also pushes the data to our buffer array (saved in 'record.streamData').
    record.streamData ?= stream._readableState.buffer.slice()

    stream._readableState.buffer.push = ->
      record.streamData.push arguments...
      [].push.apply this, arguments

    stream._readableState.buffer.unshift = ->
      record.streamData.unshift arguments...
      [].push.apply this, arguments

    stream.on "end", ->
      record.payload = Buffer.concat record.streamData
      delete record.streamData

  createReadStream: (request, buffer) ->
    delete request.body
    Streamifier.createReadStream buffer

  openDb: (callback) ->
    Async.waterfall [
      (next) =>
        Mongo.MongoClient.connect @options.dbUrl, next

      (db, next) =>
        db.collection @options.recordsName, _.partial(next, _, db)

      (db, collection, next) =>
        @recordsCollection = collection
        return next(null, db, collection) if @options.action isnt "record"
        collection.remove {}, _.partial(next, _, db, collection)

    ], (err, db, collection) ->
      return callback(err) if err?
      callback null, db, collection

module.exports = Radio
