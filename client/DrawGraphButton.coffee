Template.DrawGraphButton.rendered = ->
  $("#redrawButton").hide()


#------------------ functions ----------------------


  #------------------ Button definitions -----------------------

  $(".results-graph-draw").click ->
    Session.set 'drawButtonPressed', true
    Session.set 'graphRenderingStatus','Rendering...'
    Session.set 'elapsedRenderTime', 'Timing...'
    Session.set "firstRender",0
    #randomizeLayout()
    renderGraph()


Template.DrawGraphButton.helpers
  drawButtonPressed: ->
    (Session.get 'drawButtonPressed')

  scriptSelected: ->
    (Session.get 'scriptName') != null

  scriptResult: ->
    (Session.get 'scriptResult') != null

  renderingStatus: ->
    if (Session.get 'scriptResult') != null
      status = Session.get 'graphRenderingStatus'
      if status == true
        return 'Succeeded'
      else
        return status
    else
      return "Run script first"


  elapsedRenderTime: ->
    if (Session.get 'scriptResult') != null
      t = Session.get 'elapsedRenderTime'
      if t == 'N/A'
        return t
      else
        return t
    else
      return ""

durationToString = (d)->
  qt = ''
  if d.hours()
    qt = qt+d.hours()+'h,'
  if d.minutes()
    qt = qt+d.minutes()+'m,'
  if d.seconds()
    qt = qt+d.seconds()+'s,'
  if d.milliseconds()
    qt = qt+(Math.round(d.milliseconds()))+'ms'
  return qt

