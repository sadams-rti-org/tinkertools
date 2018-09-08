Template.ServerButtons.rendered = ->
  $(".server-addURL").click ->
    bootbox.prompt
      title: "Enter the URL for a graph server (http: or ws: depending on your server config)"
      value: 'ws://graph.server.domain.name:8182'
      callback: (newURL)->
        if newURL
          Session.set 'graphNames', []
          Session.set 'tinkerPopVersion', undefined
          discoverTinkerPopVersionAt newURL, (dat)->
            tpVersion = dat[1]
            if tpVersion == '0'
              alert 'No Tinkerpop-compliant server at '+newURL
            else
              Scripts.insert
                userID: Session.get 'userID'
                serverURL: newURL
                tinkerPopVersion: tpVersion
              Session.set 'serverURL', newURL
              Session.set 'tinkerPopVersion', tpVersion
              setTimeout( ->
                document.getElementById('serverSelector').value=newURL
                $("#serverSelector").change()
              ,500)
###
  $('.try-wsp').click ->
    alert "Here"
    p = wsp.open()
    for nn in [1..1000]
      window.n = nn
      p = p.then(addV)

request1 =
  op:"eval",
  processor:"",
  args:{gremlin:'g.addV(a).next()',bindings:{a:'Sam'}, language: "gremlin-groovy"}

addV = ()->
  request1.args.bindings.a = 'Sam '+window.n
  request = JSON.parse(JSON.stringify(request1))
  wsp.sendRequest(request,{requestId: uuid.new()})

import WebSocketAsPromised from 'websocket-as-promised'
window.wsap = WebSocketAsPromised
wsUrl = "ws://localhost:8182/gremlin"
window.wsp = new WebSocketAsPromised(wsUrl,
  packMessage: (data)->
    JSON.stringify(data)
  unpackMessage: (message)->
    JSON.parse(message)
  attachRequestId: (data, requestId)->
    Object.assign({requestId: requestId}, data)
  extractRequestId: (data)->
    data && data.requestId
)
window.wsp.onMessage.addListener((message)-> console.log JSON.parse(message))
###

Template.ServerButtons.helpers
  serverSelected: ->
    (Session.get 'serverURL') != null


discoverTinkerPopVersionAt = (url, callback)->
  callback([0,3])
  #Meteor.call 'discoverTinkerPopVersionAt', url, (err,res)->
  #  callback(res)