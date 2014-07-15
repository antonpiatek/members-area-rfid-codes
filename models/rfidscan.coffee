module.exports = (db, models) ->
  Rfidscan = db.define 'rfidscan', {
    id:
      type: 'number'
      serial: true
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
      defaultValue: {}

    createdAt:
      type: 'date'
      required: true
      time: true

    updatedAt:
      type: 'date'
      required: true
      time: true

  },
    timestamp: true
    hooks: db.applyCommonHooks {}

  Rfidscan.modelName = 'Rfidscan'
  return Rfidscan
