Controller = require 'members-area/app/controller'

module.exports = class RfidCodes extends Controller
  @before 'ensureAdmin', only: ['settings']
  @before 'loadRoles', only: ['settings']

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
              else
                thisCode.username = u.username
                thisCode.fullname = u.fullname

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
