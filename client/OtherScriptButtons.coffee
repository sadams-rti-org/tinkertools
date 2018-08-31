Template.OtherScriptButtons.rendered = ->

  $(".script-delete").click ->
    deadName = $("#scriptSelector").val()
    if deadName
      Session.set 'scriptName',null
      window.ScriptEditor.setValue 'Select a script from above or add a named script first using the [+Add] button.'
      Meteor.call 'removeScript',Session.get('userID'),Session.get('serverURL'),Session.get('graphName'),deadName


  $(".script-save").click ->
    saveName = $("#scriptSelector").val()
    userID = Session.get 'userID'
    serverURL = Session.get 'serverURL'
    graphName = Session.get 'graphName'
    scriptName = Session.get 'scriptName'
    code = window.ScriptEditor.getValue()
    record = Scripts.findOne({userID: userID, serverURL: serverURL, graphName: graphName, scriptName: scriptName})
    if not record  #save a copy of the example script into this user's scripts
      Scripts.insert
        userID: userID
        serverURL: serverURL
        graphName: graphName
        scriptName: saveName
        scriptCode: code
        scriptResult: {}
    else
      if saveName != ''
        selector =
          userID: Session.get 'userID'
          serverURL: Session.get 'serverURL'
          graphName: Session.get 'graphName'
          scriptName: saveName
        modifier =
          $set:
            scriptResult: {} #(Session.get "scriptResult") #window.resultsEditor.get()
            scriptCode: code
        Meteor.call 'updateScript',selector,modifier

  $(".script-duplicate").click ->
    oldName = $("#scriptSelector").val()
    suggestion = "<copy of> " + oldName
    bootbox.prompt
      title: "Enter the name for the new script"
      value: suggestion
      callback: (newName)->
        if newName
          Scripts.insert
            userID: Session.get 'userID'
            serverURL: Session.get 'serverURL'
            graphName: Session.get 'graphName'
            scriptName: newName
            scriptCode: window.ScriptEditor.getValue()
            scriptResult: {}
            bluemixUsername: window.BluemixUsername
            bluemixAPI: window.BluemixAPI
            bluemixPassword: window.BluemixPassword

          Session.set 'scriptName', newName
          setTimeout( ->
            document.getElementById('scriptSelector').value=newName
          ,500)


Template.OtherScriptButtons.helpers
