PersonController = require 'members-area/app/controllers/person'

module.exports =
  initialize: (done) ->
    @app.addRoute 'all' , '/rfidcodes' , 'members-area-rfid-codes#rfid-codes#list'
    @app.addRoute 'all', '/settings/rfid-codes', 'members-area-rfid-codes#rfid-codes#settings'
    @app.addRoute 'post' , '/rfidcodes/open' , 'members-area-rfid-codes#rfid-codes#open'
    @hook 'render-person-view' , @modifyUserPage.bind(this)
    @hook 'models:initialize', @modifyUserModel.bind(this)
    @hook 'navigation_items', @modifyNavigationItems.bind(this)
    @hook 'models:initialize', ({models}) =>
      models.Rfidscan.hasOne 'user', models.User, reverse: 'rfidscan'
    PersonController.before @processRfid, only: ['view']
    done()

  modifyUserPage: (options, done) ->
    {controller, $} = options
    return done() unless controller.loggedInUser.can('admin')

    #Get meta for currently selected user (not request user)
    codes = controller.user.rfidcodes

    htmlForExistingCode = (code) ->
      """
      <li>
        <form method='POST'>
          <input type='hidden' name='deleteRfid' value='y'>
          <input type='hidden' name ='code' value='#{code}'>#{code}
          <input type='submit' value='X'>
        </form>
      </li>
      """
    htmlForExistingCodes = ->
      if codes.length
        """
        <ul>
          #{(htmlForExistingCode(code) for code in codes).join("\n")}
        </ul>
        """
      else
        """
        <ul>
          <li>This user has no RFID codes, add one below</li>
        </ul>
        """

    htmlToAdd = """
      <h3>Manage RFID Code</h3>
      <h4>Existing codes</h4>
      #{htmlForExistingCodes()}
      <form method='POST' class='form-horizontal'>
        <h4>Add a code</h4>
        <input type='hidden' name='addNewRfid' value='rfid'>
        <div class="control-group">
          <label for="rfid" class="control-label">RFID Code</label>
          <div class="controls">
            <input id="rfid" name="rfid" placeholder="00000000">
          </div>
        </div>
        <div class="control-group">
          <div class="controls">
            <button type="Submit" class="btn-success">Add</button>
          </div>
        </div>
      </form>
      """

    $(".main").append htmlToAdd

    done()

  processRfid: (done) ->
    return done() unless @loggedInUser.can('admin')
    if @req.method is 'POST' and @req.body.addNewRfid
      @user.addRfidCode(@req.body.rfid)
      @user.save done
    else if @req.method is 'POST' and @req.body.deleteRfid
      @user.deleteRfidCode(@req.body.code)
      @user.save done
    else
      done()

  modifyUserModel: (options) ->
    options.models.User.instanceProperties.rfidcodes =
      get: ->
        @meta.rfidcodes ?= []
    options.models.User.instanceMethods.addRfidCode = (newCode) ->
      @rfidcodes.push(newCode) unless newCode in @rfidcodes
      @setMeta rfidcodes: @rfidcodes
    options.models.User.instanceMethods.deleteRfidCode = (code) ->
      index = @rfidcodes.indexOf(code)
      if index >= 0
        @rfidcodes.splice(index, 1)
        @setMeta rfidcodes: @rfidcodes

  modifyNavigationItems: ({addItem}) ->
    addItem 'settings',
      title: 'RFID codes'
      id: 'members-area-rfid-codes-settings'
      href: '/settings/rfid-codes'
      priority: 20
      permissions: ['admin']
    return
