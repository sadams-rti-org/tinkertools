Template.AdminTools.rendered = ->
  $(".all-user-file-export").click ->
    alert 'here'
    objs = Scripts.find({}).fetch()
    delete each._id for each in objs
    delete each.scriptResult for each in objs
    data = [JSON.stringify objs,null, 4]
    blob = new Blob(data, {type: "application/json;charset=utf-8"})
    saveAs(blob,'tinkertools-user-db.json')

  $(".all-user-file-import").click ->
    bootbox.dialog
      title: "Select a tinkertools db file to be uploaded (JSON)"
      message: '<input type="file" id="fileName" onchange="startRead()"/>Preview:<textarea id="fileContents" />'
      buttons:
        success:
          label: "Import"
          className: "btn-success"
          callback: ()->
            try
              objs = JSON.parse $('#fileContents').val()
            catch e
              alert 'Syntax error in upload file - Expecting JSON'
              return
            Scripts.insert each for each in objs


#******************** Helpers

Template.AdminTools.helpers
  userNames: ->
    allEntries = Scripts.find().fetch()
    all = (each.userID for each in allEntries)
    nodups = all.filter (v, i, a)->
      a.indexOf(v) == i
    if nodups.length == 0
      return []
    return nodups

  userName: ->
    @

  userAccountNames: ->
    allEntries = Meteor.call 'allUserIDs',  (err,res)->
      Session.set 'allUserIDs', res
    return Session.get 'allUserIDs'


  userAccountName: ->
    @

  usersOnline: ->
    Meteor.users.find({ "status.online": true })

  userOnline: ->
    @.emails[0].address

  serverURLs: ->
    allEntries = Scripts.find().fetch()
    all = (each.serverURL for each in allEntries)
    nodups = all.filter (v, i, a)->
      a.indexOf(v) == i
    if nodups.length == 0
      return []
    return nodups

  serverURL: ->
    @