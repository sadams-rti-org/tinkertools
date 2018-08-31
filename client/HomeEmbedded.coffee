Template.HomeEmbedded.rendered = ->
  Session.set('useLabelPrefix', true)
  Session.set('keyForNodeLabel', "null")

  wsUri = Session.get "serverURL"
  window.wsConnect = ()->
    console.log("connecting to ",wsUri)
    document.getElementById('ws-status').innerHTML = "<p style='font-size:16px; background-color: yellow; color: black;'>trying Websocket connection...</p>"
    window.socketToJanus = new WebSocket(wsUri+"/gremlin")
    window.socketToJanus.onmessage = (msg) ->   #example send method
      data = msg.data
      json = JSON.parse(data)
      window.dispatcher(json)
    window.socketToJanus.onopen = () ->
      document.getElementById('ws-status').innerHTML = "<p style='font-size:16px; background-color: white; color: green;'>connected via Websocket</p>"
      console.log("connected to", wsUri)
    window.socketToJanus.onclose = ()->
      document.getElementById('ws-status').innerHTML = "<p style='font-size:16px; background-color: white; color: red;'>not connected</p>"
      console.log("closed to", wsUri)
      setTimeout(window.wsConnect,3000);  #attempt to reconnect

  Session.set "usingWebSockets", true
  try
    window.wsConnect();  #connect the websocket
  catch
    Session.set "usingWebSockets", false
    document.getElementById('ws-status').innerHTML = "<p style='font-size:16px; background-color: white; color: black;'>Connected via HTTP</p>"

#*************** utilities
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

#********************* Widgets
Meteor.Spinner.options =
  lines: 13 # The number of lines to draw
  length: 10 # The length of each line
  width: 5 # The line thickness
  radius: 15 # The radius of the inner circle
  corners: 0.7 # Corner roundness (0..1)
  rotate: 0 # The rotation offset
  direction: 1 # 1: clockwise, -1: counterclockwise
  color: '#fff' # #rgb or #rrggbb
  speed: 1 # Rounds per second
  trail: 60 # Afterglow percentage
  shadow: true # Whether to render a shadow
  hwaccel: false # Whether to use hardware acceleration
  className: 'spinner' # The CSS class to assign to the spinner
  zIndex: 2e9 # The z-index (defaults to 2000000000)
  top: 'auto' # Top position relative to parent in px
  left: 'auto' # Left position relative to parent in px



#******************** Buttons


#******************** Helpers

Template.HomeEmbedded.helpers
  isAdmin: ->
    (Session.get 'userID') == (Session.get 'admin-userID')
  notAdmin: ->
    (Session.get 'userID') != (Session.get 'admin-userID')
  userLoggedIn: ->
    (Session.get 'userID') != null

  graphSelected: ->
    (Session.get 'graphName') != null
  scriptSelected: ->
    (Session.get 'scriptName') != null
  scriptResult: ->
    #(Session.get 'scriptResult')
    (Session.get 'showJSONResult')

  graphToShow: ->
    (Session.get 'graphFoundInResults')
  drawingGraph: ->
    #(Session.get 'drawButtonPressed')
    (Session.get 'drawGraphResult')