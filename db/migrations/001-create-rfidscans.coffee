async = require 'async'

module.exports =
  up: (done) ->
    columns =
      id:
        type: 'number'
        serial: true
        required: true
        primary: true

      rfidcode:
        type: 'text'
        required: true

      user_id:
        type: 'number'
        required: false

      location:
        type: 'text'
        required: true

      successful:
        type: 'boolean'
        required: true

      when:
        type: 'date'
        required: true

      meta:
        type: 'object'
        required: true

      createdAt:
        type: 'date'
        required: true
        time: true

      updatedAt:
        type: 'date'
        required: true
        time: true

    rfidscanUserIndex =
      table: 'rfidscan'
      columns: ['user_id', 'when']
      unique: false

    async.series
      createTable: (next) => @createTable 'rfidscan', columns, next
      addPaymentUserIndex: (next) => @addIndex 'rfidscan_ref_idx', rfidscanUserIndex, next
    , (err) ->
      console.dir err if err
      done err

  down: (done) ->
    @dropTable 'rfidscan', (err) ->
      console.dir err if err
      done err
