Template.ResultsVisMinimal.rendered = ->
  Session.set 'useLabelPrefix', true

  #-------- set widget removal hook to clear graph and stop physics sim -----------
  this.find('.results-vis')._uihooks
  removeElement: (node)->
    window.visnetwork.destroy()

  #------------ Widget setup --------------
  container = document.getElementById 'mynetwork'
  config = document.getElementById 'vis-config'
  $(config).hide()
  visOptions = Session.get 'visOptions'
  defaultOptions =
    interaction:
      hover: true
      navigationButtons: true
      multiselect: true
    physics: true
    nodes:
      labelHighlightBold: true
      font:
        face: 'arial'
      hidden: false
      borderWidth: 1
      color:
        hover:
          border: '#ffff00'
          background: '#0066cc'
        highlight:
          border: '#ff0000'
          background: '#ffff00'
    edges:
      hidden: false
      arrows:
        to:
          enabled: true
          scaleFactor: 0.5
      color:
        highlight:'#ff0000'
        hover:'#0066cc'
  if visOptions == undefined
    options = defaultOptions
  else
    options = visOptions
  data = []
  console.log "installing window.visnetwork"
  window.visnetwork = new vis.Network container, data, options



  window.visnetwork.on('selectEdge', (params)->   # remember the selected edge
    console.log params

  )

  window.visnetwork.on('selectNode', (params)->   # remember the selected node
    console.log params

  )

  window.visnetwork.on('doubleClick', (params)->   # open a dialog for the selected element
    if params.nodes.length != 0 # then a node was doubleClicked
      element = window.visnetwork.nodesHandler.body.data.nodes.get(params.nodes[0])
      html = popupDialogForElement(element.element)
      if (Session.get 'tinkerPopVersion') == '3'
        title = 'Vertex: '+element.element.id
      else
        title = 'Vertex: '+element.element._id
    else
      if params.edges.length == 1 # then an edge was doubleClicked
        element =  window.visnetwork.edgesHandler.body.data.edges.get(params.edges[0])
        html = popupDialogForElement(element.element)
        title = 'Edge: '+element.element._id
      else
        return #background was doubleClicked, nothing to do yet
    div = document.createElement 'div'
    div.class = 'doubleClick-dialog'
    div.innerHTML = html
    $(".vis-network").append div
    $(div).dialog({title: title,resizable: true})
  )

  $(".results-graph-fit").click ->
    window.visnetwork.fit()

  #-------------- Viz option controls --------------------
  $(".vis-options-node-hideShow").prop('checked', true)
  $(".vis-options-node-hideShow").change ->
    oldState = $(".vis-options-node-hideShow").prop('checked')
    newState = !oldState
    window.visnetwork.setOptions {nodes:{hidden: newState}}

  $(".vis-options-edge-hideShow").prop('checked', true)
  $(".vis-options-edge-hideShow").change ->
    oldState = $(".vis-options-edge-hideShow").prop('checked')
    newState = !oldState
    window.visnetwork.setOptions {edges:{hidden: newState}}

  $(".vis-options-physics-toggle").prop('checked', true)
  $(".vis-options-physics-toggle").change ->
    state = $(".vis-options-physics-toggle").prop('checked')
    window.visnetwork.setOptions {physics: state}

  $('.all-settings').click (evt)->
    $('#vis-config').dialog({title: 'Visualization Options',resizable: true,width:500,height:300})

  #-------------- Node Label Selector --------------------
  $("#nodeLabelProperty").change ->
    key = $("#nodeLabelProperty").val()
    Session.set 'keyForNodeLabel', key
    nodes = window.visnetwork.nodesHandler.body.data.nodes
    window.visnetwork.stopSimulation()
    nodes.forEach (node)->
      node.label = labelForVertex(node.element,key)
      nodes.update node
    window.visnetwork.startSimulation()

#---------------- Helpers --------------------------

Template.ResultsVisMinimal.helpers
  vertexPropertyNames: ->
    Session.get 'vertexPropertyNames'
  vertexPropertyName: ->
    @

#----------------- Functions -----------------------

#functions supplied by ResultsVis.coffee that loads before me