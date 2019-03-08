Template.RunScriptButton.rendered = ->
  #------------------ functions ----------------------

  #------------------ Button definitions -----------------------

  $(".script-run").click ->
    Session.set 'graphFoundInResults', false
    serverURL = Session.get 'serverURL'
    scriptName = Session.get 'scriptName'
    userID = Session.get 'userID'
    Session.set 'runStatus','Running...'
    Session.set 'queryTime','Timing...'
    Session.set "firstRender",0
    Session.set 'graphFoundInResults', false
    Session.set 'graphRenderingStatus', ''
    Session.set 'elapsedRenderTime', ''
    Session.set 'elapsedTime','Timing...'
    Session.set 'drawButtonPressed', false
    Session.set 'startTime', moment().toDate()
    Session.set 'scriptResult', null
    Session.set 'elementsInResults',{vertices:[],edges:[]}
    if window.resultsEditor
      window.resultsEditor.set {}
    if serverURL && scriptName
      if window.ScriptEditor != undefined
        scriptCode = window.ScriptEditor.getValue()
      else
        scriptCode = Session.get 'scriptCode'
      if (Session.get "usingWebSockets")
        window.PARTIALRESULTS = []
        window.socketToJanus.onmessage = (msg) ->
          console.log msg
          endTime = Date.now()
          data = msg.data
          json = JSON.parse(data)
          if json.status.code >= 500
            Session.set 'runStatus', json.status.message
            alert "Error in processing Gremlin script: "+json.status.message
          else
            if json.status.code == 206  #partial data, stash this and wait for more
              window.PARTIALRESULTS =  _.union(window.PARTIALRESULTS, json.result.data)
              return
            if json.status.code == 204
              results = []
            if json.status.code == 200  #final result, but may have partial
              results =  _.union(window.PARTIALRESULTS, json.result.data)
            processResults(results, true, startTime - endTime)
        request =
          requestId: uuid.new(),
          op:"eval",
          processor:"",
          args:{gremlin: scriptCode, bindings: {}, language: "gremlin-groovy"}
        startTime = Date.now()
        window.socketToJanus.send(JSON.stringify(request))
      else
        Meteor.call "runScript", userID, serverURL,(Session.get 'tinkerPopVersion'), Session.get('usingWebSockets'), scriptName, scriptCode, {}, (error, result) ->
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
        return



  #-------------- Switches for showing JSON and/or Graph results --------------------
  $(".showJSONResult").prop('checked', false)
  Session.set('showJSONResult', false)

  $(".showJSONResult").change ->
    Session.set('showJSONResult', $(".showJSONResult").prop('checked'))


  $(".drawGraphResult").prop('checked', false)
  Session.set('drawGraphResult', false)

  $(".drawGraphResult").change ->
    state = $(".drawGraphResult").prop('checked')
    Session.set('drawGraphResult', state)
    Session.set('firstRender', 0)
    if state == true
      $("#redrawButton").show()
      Session.set 'drawButtonPressed', true
      Session.set 'graphRenderingStatus','Rendering...'
      Session.set 'elapsedRenderTime', 'Timing...'
      randomizeLayout()
      renderGraph()
    else
      $("#redrawButton").hide()
      Session.set 'graphRenderingStatus','Ready'
      Session.set 'elapsedRenderTime', ''



Template.RunScriptButton.helpers
  scriptSelected: ->
    (Session.get 'scriptName') != null

  scriptResult: ->
    (Session.get 'scriptResult') != null

  runStatus: ->
    status = Session.get 'runStatus'
    if status == true
      return 'Succeeded'
    if status == false
      return 'Failed'
    return status

  queryTime: ->
    t = Session.get 'queryTime'
    if t == 'N/A'
      return t
    else
      return t

  elapsedTime: ->
    t = Session.get 'elapsedTime'
    if t == 'N/A'
      return t
    else
      return t


window.durationToString = (d)->
  qt = ''
  if d.hours()
    qt = qt+d.hours()+'h'
  if d.minutes()
    qt = qt+d.minutes()+'m'
  if d.seconds()
    qt = qt+d.seconds()+'s'
  if d.milliseconds()
    qt = qt+(Math.round(d.milliseconds()))+'ms'
  return qt

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
