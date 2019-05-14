Template.HomeClassic.rendered = ->
  Session.set('useLabelPrefix', true)
  Session.set('keyForNodeLabel', "null")


  window.wsConnect = (wsUri)->
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
      window.WSURL = wsUri
      window.detectGraphSON3()

    window.socketToJanus.onclose = ()->
      document.getElementById('ws-status').innerHTML = "<p style='font-size:16px; background-color: white; color: red;'>not connected</p>"
      console.log("closed to", window['WSURL'], ' attempting reconnect')
      setTimeout(window.wsConnect(window['WSURL']),3000);  #attempt to reconnect

  Session.set "usingWebSockets", true
  try
    window.wsConnect(Session.get "serverURL");  #connect the websocket
  catch
    Session.set "usingWebSockets", false
    document.getElementById('ws-status').innerHTML = "<p style='font-size:16px; background-color: white; color: black;'>Connected via HTTP</p>"

#*************** utilities

window.detectGraphSON3 = ()->
  bindings = {}
  script = '[1]'
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if json.status.code == 204
          results = []
        else
          results = json.result.data
        window.setFlagForGraphSON3(results)
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in Vertex Retriever', script, bindings, (error,result)->
      window.setFlagForGraphSON3(results.results)

window.setFlagForGraphSON3 = (results)->
  if results['@type'] == 'g:List'
    window.UsingGraphSON3 = true
  else
    window.UsingGraphSON3 = false
  resultsShouldBe =[
    {
      "@type": "g:List",
      "@value": [
        {
          "@type": "g:Int32",
          "@value": 1
        }
      ]
    }
  ]

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

Template.HomeClassic.helpers
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