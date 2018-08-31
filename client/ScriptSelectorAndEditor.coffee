defaultScript = 'Select a script from above or add a named script first using the [+Add] button.'

Template.ScriptSelectorAndEditor.rendered = ->

  Tracker.autorun (e)->
    window.ScriptEditor = AceEditor.instance 'scriptEditor'
    if window.ScriptEditor.loaded == true
      e.stop()
      window.ScriptEditor.insert defaultScript
      Session.set 'scriptCode',''
     # window.ScriptEditor.setTheme('ace/theme/github')
      window.ScriptEditor.getSession().setMode('ace/mode/groovy')
      window.ScriptEditor.getSession().setUseWrapMode(true)
      window.ScriptEditor.getSession().setWrapLimitRange()



  $("#scriptSelector").change ->
    scriptName = $("#scriptSelector").val()
    Session.set 'scriptName', scriptName
    Session.set 'scriptResult', null
    Session.set 'queryTime', 'N/A'
    Session.set 'elapsedTime', 'N/A'
    Session.set 'runStatus', 'Ready'
    Session.set 'graphFoundInResults', false
    Session.set 'graphRenderingStatus', 'Run script first'
    Session.set 'drawButtonPressed', false
    Session.set 'renderStartTime', null
    Session.set 'scriptCode', scriptCode()
    window.ScriptEditor.setValue(Session.get 'scriptCode')
    if window.resultsEditor
      window.resultsEditor.set {}

  $(".script-url-test").click ->
    open(scriptURLForStandalone())


#------------------ Utility functions  ----------------------
scriptCode = ->
  userID = Session.get 'userID'
  serverURL = Session.get 'serverURL'
  graphName = Session.get 'graphName'
  scriptName = Session.get 'scriptName'
  if userID && serverURL && graphName && scriptName
    record = Scripts.findOne({userID: userID, serverURL: serverURL, graphName: graphName, scriptName: scriptName})
    if not record
      record = Scripts.findOne({userID: (Session.get 'examples-userID'), serverURL: serverURL, graphName: graphName, scriptName: scriptName})
    Session.set 'scriptCode',record.scriptCode
    Session.set 'scriptResult', null
    #window.resultsEditor.set {}
    return record.scriptCode
  else
    return ''

stripComments = (script)->
  stripped = script.replace(/(?:\/\*(?:[\s\S]*?)\*\/)|(?:([\s;])+\/\/(?:.*)$)/gm,'')   #strip comments of all kinds
  #stripped = stripped.replace(/\t+/g,' ')  #replace tabs with spaces
  return stripped

escapeDollarSignInStrings = (script)->
  return script.replace(/\$/g,'\\$')   #escape $ with \$ due to Java string insertion matcher

scriptURLForStandalone = ->
    if (Session.get 'tinkerPopVersion') == '2'
      url = (Session.get 'serverURL')+'/graphs/'+(Session.get 'graphName')+'/tp/gremlin?script='+ encodeURIComponent(escapeDollarSignInStrings(stripComments(scriptCode())))
    if (Session.get 'tinkerPopVersion') == '3'
      url = (Session.get 'serverURL')+'/?gremlin='+ encodeURIComponent(escapeDollarSignInStrings(stripComments(scriptCode())))
    return url

#------------------ Button definitions -----------------------

Template.ScriptSelectorAndEditor.helpers
  scriptNames: ->
    userID = Session.get 'userID'
    serverURL = Session.get 'serverURL'
    graphName = Session.get 'graphName'
    foo = Session.get 'scriptName'
    if userID && graphName && serverURL
      allFor = Scripts.find({userID: userID, serverURL: serverURL, graphName: graphName}).fetch()
      all = (each.scriptName for each in allFor)
      if (Session.get 'userID') != (Session.get 'examples-userID')
        allExamples = Scripts.find({userID: (Session.get 'examples-userID'),serverURL: serverURL, graphName: graphName}).fetch()
        exampleScripts = (each.scriptName for each in allExamples)
        all = exampleScripts.concat all
      nodups = all.filter (v, i, a)->
        a.indexOf(v) == i
      if nodups.length == 0
        return []
      nonNulls = _.reject nodups, (x)->
        return !x
      sorted = _.sortBy(nonNulls, (e)->
        return e.toLocaleLowerCase()
      )
      return sorted

  scriptName: ->
    @

  graphSelected: ->
    (Session.get 'graphName') != null

  scriptSelected: ->
    (Session.get 'scriptName') != null

  scriptURL: ->
    scriptURLForStandalone()

  notBluemix: ->
    (Session.get 'serverURL') != window.BluemixGraphService

  tinkerPopVersion : ->
    Session.get 'tinkerPopVersion'