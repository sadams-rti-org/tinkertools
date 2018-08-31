Template.ScriptResults.rendered = ->
  #------------------ Widget definition ----------------------
  container = document.getElementById("gremlinResultEditor")
  options =
    mode: "code"
    modes: [
      "code"
      "form"
      "text"
      "tree"
      "view"
      ]
  window.resultsEditor = new JSONEditor(container, options)
  result = Session.get 'scriptResult'
  if result == null
    contents = ''
  else
    contents = result
  window.resultsEditor.set contents
  window.resultsEditor.$blockScrolling = Infinity


  #------------------ Utility functions  -----------------------


  #------------------ Button definitions -----------------------


  $(".script-spawn").click ->
    open('/results?json='+JSON.stringify(Session.get 'scriptResult')+'&script='+encodeURIComponent(Session.get 'scriptCode'))

  $(".results2csv").click ->
    csv = Papa.unparse(Session.get('scriptResult'))
    window.open('data:text/csv;charset=utf-8,' + escape(csv));

Template.ScriptResults.helpers
  successOrFailure: ->
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
      return t+' ms'
  elapsedTime: ->
    t = Session.get 'elapsedTime'
    if t == 'N/A'
      return t
    else
      return t+' ms'

  graphSelected: ->
    (Session.get 'graphName') != null

  scriptSelected: ->
    (Session.get 'scriptName') != null

  scriptResult: ->
    (Session.get 'scriptResult') != null

  elementsInResults: ->
    obj = Session.get 'elementsInResults'
    resp = ''
    if obj.vertices.length > 0
      resp = resp+ obj.vertices.length + ' vertices'
      if obj.edges.length > 0
        resp = resp + ' and '
    if obj.edges.length > 0
      resp = (resp + obj.edges.length) + ' edges'
    resp +  ' were found in these results'

  elementsFoundInResults: ->
    obj = Session.get 'elementsInResults'
    (obj.vertices.length + obj.edges.length) > 0