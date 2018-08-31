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

Template.ServerButtons.helpers
  serverSelected: ->
    (Session.get 'serverURL') != null


discoverTinkerPopVersionAt = (url, callback)->
  callback([0,3])
  #Meteor.call 'discoverTinkerPopVersionAt', url, (err,res)->
  #  callback(res)