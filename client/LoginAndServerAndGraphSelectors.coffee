Template.LoginAndServerAndGraphSelectors.rendered = ->

  $("#serverSelector").change ->
    serverURL = $("#serverSelector").val()
    Session.set 'graphName', 'the default graph'
    #$("#graphSelector").val(null)
    Session.set 'scriptName', null
    $("#scriptSelector").val(null)
    if (window.ScriptEditor)
      window.ScriptEditor.setValue 'Select a script from above or add a named script first using the [+Add] button.'
    Session.set 'scriptResult', null
    Session.set 'graphNames', []
    Session.set 'serverURL', serverURL
    Session.set 'tinkerPopVersion', '3'
    Session.set 'runStatus', 'Nothing run'
    Session.set 'queryTime','N/A'
    Session.set 'elapsedTime','N/A'
    Session.set('keyForNodeLabel', "null")
    Session.set "usingWebSockets", true
    try
      window.wsConnect(serverURL);  #connect the websocket
    catch
      Session.set "usingWebSockets", false
      document.getElementById('ws-status').innerHTML = "<p style='font-size:16px; background-color: white; color: black;'>Connected via HTTP</p>"


  #------------------ Utility functions  -----------------------
  window.startRead = (evt)->
    element = document.getElementById("fileName")
    if element
      if element.files[0].size > 10000000
        return getAsTextPreview element.files[0]
      else
        return getAsText element.files[0]
    element = document.getElementById("files")
    if element
      if element.files[0].size > 10000000
        return getAsTextPreview element.files[0]
      else
        return getAsText element.files[0]

  window.getAsTextPreview = (readFile)->
    reader = new FileReader
    reader.readAsText (readFile.slice(0,10000000)), "UTF-8"
    reader.onload = fileLoaded
  window.getAsText = (readFile)->
    reader = new FileReader
    reader.readAsText (readFile), "UTF-8"
    reader.onload = fileLoaded

  window.fileLoaded = (evt)->
    $('#fileContents').val(evt.target.result)

  window.BluemixGraphService = 'Bluemix Graph Service'
  #------------------ Button definitions -----------------------


#------------------ Helpers -----------------------


Template.LoginAndServerAndGraphSelectors.helpers

  versionNumber: ->
    Session.get('versionNumber')

  serverSelected: ->
    (Session.get 'serverURL') != null

  serverURLs: ->
    userID = Session.get 'userID'
    allForUserID = Scripts.find({userID: userID}).fetch()
    all = (each.serverURL for each in allForUserID)
    if userID
      if (Session.get 'userID') != (Session.get 'examples-userID')
        allExamples = Scripts.find({userID: Session.get 'examples-userID'}).fetch()
        exampleServerURLs = (each.serverURL for each in allExamples)
        all = exampleServerURLs.concat all
      nodups = all.filter (v, i, a)->
        a.indexOf(v) == i
      if nodups.length == 0
        return []
      return nodups

  serverURL: ->
    @

  graphNames: ->
    serverURL = Session.get 'serverURL'
    if serverURL
      Session.set 'graphNames',['the default graph']
    return Session.get 'graphNames'

  graphName: ->
    @

  graphSelected: ->
    (Session.get 'graphName') != null

  isAdmin: ->
    (Session.get 'userID') == (Session.get 'admin-userID')
  notAdmin: ->
    (Session.get 'userID') != (Session.get 'admin-userID')
  userLoggedIn: ->
    (Session.get 'userID') != null

discoverTinkerPopVersionAt = (url, callback)->
  Meteor.call 'discoverTinkerPopVersionAt', url, (err,res)->
    callback(res)