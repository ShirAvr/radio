class Record

  constructor: (@id, info) ->
    { @path, @method, @headers, @delay, @query } = info

  save: (collection, callback) ->
    collection.insert this, callback

module.exports = Record