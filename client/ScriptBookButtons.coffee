Template.ScriptBookButtons.rendered = ->
  $(".script-add").click ->
    bootbox.prompt "Enter the name for the new script", (newName)->
      if newName
        if (Session.get 'serverURL') == window.BluemixGraphService
          Scripts.insert
            userID: Session.get 'userID'
            serverURL: Session.get 'serverURL'
            graphName: Session.get 'graphName'
            scriptName: newName
            scriptCode: "g.V().count()"
            scriptResult: {}
            bluemixUsername: window.BluemixUsername
            bluemixAPI: window.BluemixAPI
            bluemixPassword: window.BluemixPassword
        else
          Scripts.insert
              userID: Session.get 'userID'
              serverURL: Session.get 'serverURL'
              graphName: Session.get 'graphName'
              scriptName: newName
              scriptCode: "g.V().count()"
              scriptResult: {}
        Session.set 'scriptName', newName
        window.ScriptEditor.setValue 'g.V().count()'
        setTimeout( ->
          document.getElementById('scriptSelector').value=newName
        ,500)

  $(".gremlin-docs").click ->
    open("http://gremlindocs.com/")

  $(".groovy-docs").click ->
    open("http://www.groovy-lang.org/groovy-dev-kit.html")

  $(".tinkerpop-docs").click ->
    open("http://tinkerpop.apache.org/docs/3.1.1-incubating/reference/")

  $(".getting-started").click ->
    open("http://tinkerpop.apache.org/docs/3.2.0-incubating/tutorials/getting-started/")

  $(".sql2gremlin").click ->
    open("http://sql2gremlin.com/")


Template.ScriptBookButtons.helpers
  scriptSelected: ->
    (Session.get 'scriptName') != null
  isTinkerPopVersion3 : ->
    "3" == Session.get 'tinkerPopVersion'
  isTinkerPopVersion2 : ->
    "2" == Session.get 'tinkerPopVersion'