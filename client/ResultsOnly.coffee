Template.ResultsOnly.rendered = ->
  #------------------ Widget definition ----------------------
  container = document.getElementById("gremlinResultEditor")
  options =
    mode: "view"
    modes: [
      "code"
      "form"
      "text"
      "tree"
      "view"
      ]
  window.resultsEditor = new JSONEditor(container, options)
  window.resultsEditor.set Session.get 'scriptResults'
  $("#gremlinResultEditor").height($(window).height())
  $(window).resize ->
    $("#gremlinResultEditor").height($(window).height())

Template.ResultsOnly.helpers
  lastScript: ->
    Session.get 'scriptCode'