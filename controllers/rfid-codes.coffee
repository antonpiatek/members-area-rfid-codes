Controller = require 'members-area/app/controller'

module.exports = class RfidCodes extends Controller

    list: (done)->
        @rendered = true # We're handling rendering
        #TODO Security! Need to check additional secret here. Secret should probably be set via a new admin view for rfidcodes
        if true
            @res.json 400, {errorCode: 400, errorMessage: "Invalid or no auth"}
            return done()
        else
            keyholderRoleId = @plugin.get('trusteeRoleId') ? 1
            memberRoleId    = @plugin.get('memberRoleId') ? 1
            @req.models.User.find().run(err, users) =>
                codes = {}
                if(err)
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
