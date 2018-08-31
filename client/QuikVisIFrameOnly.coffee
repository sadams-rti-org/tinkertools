Template.QuikVisIFrameOnly.rendered = ->
  Session.set('keyForNodeLabel', "null")

  if (Session.get 'scripts').length =1
    scriptObject = (Session.get 'scripts')[0]
    Session.set 'scriptName', scriptObject.title
    runScriptAndDrawResults(scriptObject.script)
  $("#scriptSelector").change ->
    scriptName = $("#scriptSelector").val()
    for each in (Session.get 'scripts')
      if scriptName == each.title
        scriptCode = each.script
        Session.set 'scriptName', each.title
    runScriptAndDrawResults(scriptCode)


#*************** utilities

runScriptAndDrawResults = (scriptCode)->
  Session.set 'graphFoundInResults', false
  Session.set 'graphRenderingStatus', ''
  Session.set 'drawButtonPressed', false
  Session.set 'scriptCode', scriptCode
  Session.set 'userID', 'quikvis'
  Session.set 'tinkerPopVersion', '3'
  Session.set 'graphFoundInResults', false
  serverURL = Session.get 'serverURL'
  graphName = Session.get 'graphName'
  scriptName = Session.get 'scriptName'
  userID = Session.get 'userID'
  Session.set 'graphFoundInResults', false
  Session.set 'graphRenderingStatus', ''
  Session.set 'elapsedRenderTime', ''
  Session.set 'elapsedTime','Timing...'
  Session.set 'drawButtonPressed', false
  Session.set 'startTime', moment().toDate()
  Session.set 'elementsInResults',{vertices:[],edges:[]}
  if window.resultsEditor
    window.resultsEditor.set {}
  if serverURL && graphName && scriptName
    if window.ScriptEditor != undefined
      scriptCode = window.ScriptEditor.getValue()
    else
      scriptCode = Session.get 'scriptCode'
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          Session.set 'runStatus', json.status.message
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
          else
            results = json.result.data
          processResults(results, true, startTime - endTime)
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: scriptCode, bindings: {}, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call "runScript", userID, serverURL,(Session.get 'tinkerPopVersion'), (Session.get "usingWebSockets"), scriptName,scriptCode,{}, (error, result) ->
        if error
          console.log  error
          alert JSON.stringify error
          return
        #console.log 'result=',JSON.stringify result
        if (result == undefined) || (result.results == undefined) || (result.results == null) || (result.results.length == 0)
          results = [null]
        else
          results = result.results
        if window.resultsEditor
          window.resultsEditor.set results
        Session.set 'scriptResult', results
        Session.set 'runStatus', result.success
        d = moment.duration(Math.round(result.queryTime*1000)/1000)
        Session.set 'queryTime', window.durationToString(d)
        d = moment.duration(Math.round((moment()-moment(Session.get 'startTime'))*1000)/1000)
        Session.set 'elapsedTime', window.durationToString(d)
        determineGraphToShow()
        Session.set 'drawButtonPressed', true
        Session.set 'graphRenderingStatus','Rendering...'
        Session.set 'elapsedRenderTime', 'Timing...'
        randomizeLayout()
        renderGraph()
      return
  return

modifyRenderingUsing = ()->
  setTimeout( ->
    gts = Session.get 'graphToShow'
    options = Session.get 'renderingOptions'
    nodes = gts.nodes
    edges = gts.edges
    for option in options
      if option.type == 'edge'
        for rendering in option.renderings
          selectionScript = rendering.selectUsing
          directives = rendering.directives
          for directive in directives
            renderingKey = (Object.keys directive)[0]
            renderingScript = directive[renderingKey]
            functionString = 'function selector(edge){return '+selectionScript+'}'
            eval functionString
            functionString = 'function renderer(edge){return '+renderingScript+'}'
            eval functionString
            for edge in edges
              if selector(edge.element)
                edge[renderingKey] = renderer(edge.element)
#alert JSON.stringify(edge)
              else
#alert 'FAILED',JSON.stringify(edge)
      if option.type == 'vertex'
        for rendering in option.renderings
          selectionScript = rendering.selectUsing
          directives = rendering.directives
          for directive in directives
            renderingKey = (Object.keys directive)[0]
            renderingScript = directive[renderingKey]
            functionString = 'function selector(vertex){return '+selectionScript+'}'
            eval functionString
            functionString = 'function renderer(vertex){return '+renderingScript+'}'
            eval functionString
            for node in nodes
              if selector(node.element)
                node[renderingKey] = renderer(node.element)
#alert JSON.stringify(node)
              else
#alert 'FAILED',JSON.stringify(node)
      window.visnetwork.nodesHandler.body.data.nodes.update nodes
      window.visnetwork.edgesHandler.body.data.edges.update edges
  ,2000)

#********************* Widgets



#******************** Buttons


#******************** Helpers

Template.QuikVisIFrameOnly.helpers
  isAdmin: ->
    (Session.get 'userID') == (Session.get 'admin-userID')
  notAdmin: ->
    (Session.get 'userID') != (Session.get 'admin-userID')
  userLoggedIn: ->
    (Session.get 'userID') != null

  scripts: ->
    Session.get 'scripts'
  multipleScripts: ->
    (Session.get 'scripts').length > 1

  script: ->
    @.title
  scriptResult: ->
    true
  graphSelected: ->
    true
  scriptSelected: ->
    (Session.get 'scriptName') != null
  drawingGraph: ->
    true
  graphToShow: ->
    (Session.get 'graphFoundInResults')
  renderingOptions: ->
    JSON.stringify (Session.get 'renderingOptions')

processResults = (results, success, queryTime) ->
  if window.resultsEditor
    window.resultsEditor.set results
  Session.set 'scriptResult', results
  Session.set 'runStatus', success
  d = moment.duration(Math.round(queryTime*1000)/1000)
  Session.set 'queryTime', window.durationToString(d)
  d = moment.duration(Math.round((moment()-moment(Session.get 'startTime'))*1000)/1000)
  Session.set 'elapsedTime', window.durationToString(d)
  determineGraphToShow()
  if ((Session.get 'graphToShow').nodes.length == 0) && ((Session.get 'graphToShow').edges.length == 0)
    Session.set 'graphRenderingStatus','No graph in result'
  else
    Session.set 'graphRenderingStatus','Ready'
    if Session.get('drawGraphResult') == true
      Session.set 'drawButtonPressed', true
      Session.set 'graphRenderingStatus','Rendering...'
      Session.set 'elapsedRenderTime', 'Timing...'
      randomizeLayout()
      renderGraph()
  return