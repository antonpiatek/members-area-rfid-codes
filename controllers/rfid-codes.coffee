Controller = require 'members-area/app/controller'

module.exports = class RfidCodes extends Controller
  @before 'ensureAdmin', only: ['settings']
  @before 'loadRoles', only: ['settings']

  open: (done) ->
    @rendered = true # We're handling rendering
    secret = @plugin.get('apiSecret')
    error = (code, object) =>
      @res.json code, object
      return done()
    if !secret?.length or @req.cookies.SECRET != secret
      return error 401, {errorCode: 401, errorMessage: "Invalid or no auth"}
    else
      {rfidcode, user_id, location, successful} = @req.body
      whenScanned = @req.body.when

      rfidcode = String(rfidcode ? "")
      user_id = parseInt(user_id ? 0, 10) if user_id?
      location = String(location ? "")
      successful = !!(String(successful ? "1") isnt "0")
      whenScanned = new Date(parseInt(whenScanned, 10))

      return error 400, {errorCode: 400, errorMessage: "No code specified"} unless rfidcode?.length
      return error 400, {errorCode: 400, errorMessage: "Invalid user_id"} unless !user_id? or (isFinite(user_id) and user_id > 0)
      return error 400, {errorCode: 400, errorMessage: "No location specified"} unless location?.length
      return error 400, {errorCode: 400, errorMessage: "Invalid date"} unless whenScanned.getFullYear() >= 2014

      entry =
        rfidcode: rfidcode
        user_id: user_id
        location: location
        successful: successful
        when: whenScanned

      @req.models.Rfidscan.create [entry], (err) =>
        if err
          console.error "ERROR OCCURRED SAVING RFIDSCAN"
          console.dir err
          return error 500, "Could not create model"
        @res.json {success: true}
        done()

  list: (done)->
    @rendered = true # We're handling rendering
    secret = @plugin.get('apiSecret')
    if !secret?.length or @req.cookies.SECRET != secret
      @res.json 401, {errorCode: 401, errorMessage: "Invalid or no auth"}
      return done()
    else
      memberRoleId    = @plugin.get('memberRoleId') ? 1
      keyholderRoleId = @plugin.get('keyholderRoleId') ? 2
      @req.models.User.find().run (err, users) =>
        codes = {}
        if err
          @res.json 500, {errorCode: 500, errorMessage: err}
          console.log err
          return done(err)
        console.log users[0]
        for u in users
          if u.meta.rfidcodes
            for code in u.meta.rfidcodes
              code = code.toLowerCase()
              #might be an existing known code
              thisCode = codes[code] ? {}

              #might manage to share an id (so deal with it)
              if thisCode.username
                thisCode.username += " and "+u.username
                thisCode.fullname += " and "+u.fullname
                delete thisCode.user_id
              else
                thisCode.username = u.username
                thisCode.fullname = u.fullname
                thisCode.user_id = u.id

              thisCode.keyholder = (keyholderRoleId in u.activeRoleIds)
              thisCode.member = (memberRoleId in u.activeRoleIds)

              #stash back in the json
              codes[code] = thisCode
        @res.json codes
      return done()

  settings: (done) ->
    @data.memberRoleId ?= @plugin.get('memberRoleId') ? 1
    @data.keyholderRoleId ?= @plugin.get('keyholderRoleId') ? 2
    @data.apiSecret ?= @plugin.get('apiSecret')
    @data.memberRoleId = parseInt(@data.memberRoleId, 10)
    @data.keyholderRoleId = parseInt(@data.keyholderRoleId, 10)

    if @req.method is 'POST'
      @plugin.set {apiSecret: @data.apiSecret, memberRoleId: @data.memberRoleId, keyholderRoleId: @data.keyholderRoleId}
    done()

  loadRoles: (done) ->
    @req.models.Role.find (err, @roles) =>
      done(err)

  ensureAdmin: (done) ->
    return done new @req.HTTPError 403, "Permission denied" unless @req.user.can('admin')
    done()
