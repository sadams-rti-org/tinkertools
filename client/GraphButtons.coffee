Template.GraphButtons.rendered = ->
  $(".graph-debug").click ->
    debugger

Template.GraphButtons.helpers
  graphSelected: ->
    (Session.get 'graphName') != null
  bluemix: ->
    (Session.get 'serverURL') == window.BluemixGraphService
