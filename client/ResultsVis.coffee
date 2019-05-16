Template.ResultsVis.rendered = ->
  Session.set 'graphRenderingStatus','Rendering...'
  Session.set('keyForNodeLabel', "null")
  Session.set('useLabelPrefix', true)
  window.setUpVis()
  Session.set 'graphRenderingStatus','Rendering...'
  graph = Session.get 'graphToShow'
  Session.set 'renderStartTime', moment().toDate()
  vn = new vis.DataSet(graph.nodes)
  ve = new vis.DataSet(graph.edges)
  window.visnetwork.setData {nodes: vn, edges: ve}
  getLabelSets()
  if (Session.get 'positions')
    positions = Session.get 'positions'
  else
    positions = {}
  for node in graph.nodes
    oldLoc = positions[node.id]
    if oldLoc
      node.x = oldLoc.x
      node.y = oldLoc.y
      node.physics = false   # pin it
  window.visnetwork.nodesHandler.body.data.nodes.update graph.nodes
  window.hidden1 = if window.hidden1 then window.hidden1 else {nodes:[],edges:[], positions:{}}
  window.hidden2 = if window.hidden2 then window.hidden2 else {nodes:[],edges:[], positions:{}}
  window.hidden3 = if window.hidden3 then window.hidden3 else {nodes:[],edges:[], positions:{}}
  window.hidden4 = if window.hidden4 then window.hidden4 else {nodes:[],edges:[], positions:{}}





#---------------- Helpers --------------------------

Template.ResultsVis.helpers
  vertexPropertyNames: ->
    Session.get 'vertexPropertyNames'
  vertexPropertyName: ->
    @
  vertexLabels: ->
    if window.visnetwork
      getLabelSets()
    Session.get 'vertexLabelSet'
  vertexLabel: ->
    @
  visWidth: ->
    if (Session.get "visWidth") then (Session.get "visWidth") else 'auto'
  visHeight: ->
    if (Session.get "visHeight") then (Session.get "visHeight") else '900px'

#----------------- Functions -----------------------

window.determineGraphToShow = ->
  #Switching to use global window.UsingGraphSON3 determined on web socket connect time
  #g3 = detectGraphSON3Element(Session.get 'scriptResult')
  if window.UsingGraphSON3
    return determineGraphToShowGraphSON3()
  else
    return determineGraphToShowGraphSON1()

detectGraphSON3Element = (obj)->
  if not obj[0] then return false
  if obj[0]['@value'] then return true
  vertFound = atLeastOneInsideGraphSON3(obj, '@type','g:Vertex')
  if vertFound then return true
  edgeFound = atLeastOneInsideGraphSON3(obj, '@type', 'g:Edge')
  return edgeFound

atLeastOneInsideGraphSON3 = (obj,key,value) ->
  if obj[key] && (obj[key]== value)
    return true
  else
    if (typeof obj == 'string') || (typeof obj == 'boolean') || (typeof obj == 'number') || (typeof obj == 'symbol') || (typeof obj == 'undefined') || ( obj == null)
      return false
    if Array.isArray(obj)  #its an array, recurse
      for subObj in obj
        answer = atLeastOneInsideGraphSON3(subObj,key,value)
        if answer then return true
    else
      for okey in Object.keys(obj)
        answer = atLeastOneInsideGraphSON3(obj[okey],key,value)
        if answer then return true
  return false


window.determineGraphToShowGraphSON1 = ->
  Session.set 'graphToShow', {nodes:[],edges:[]}
  verts = verticesInside(Session.get 'scriptResult')
  verts = _.uniq(verts,(item)->
    return item.id)
  edges = edgesInside(Session.get 'scriptResult')
  vIDsInEdges = vertIDsInEdges(edges)
  vIDsInResults = []
  vIDsInResults = (v.id for v in verts)
  missingVIDs = _.difference vIDsInEdges, vIDsInResults
  if missingVIDs.length == 0
    return setGraphToShow verts, edges
  bindings = {vIDs: missingVIDs}
  script = 'vIDs.collect{each-> g.V(each).next()}'
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if json.status.code == 204
          results = []
        else
          results = json.result.data
        addVertsToGraphToShow(results)
        addEdgesToGraphToShow edges
        addVertsToGraphToShow verts
        Session.set 'elementsInResults', {vertices: verts, edges: edges}
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in Vertex Retriever', script, bindings, (error,result)->
      addVertsToGraphToShow(result.results)
      addEdgesToGraphToShow edges
      addVertsToGraphToShow verts
      Session.set 'elementsInResults', {vertices: verts, edges: edges}


window.determineGraphToShowGraphSON3 = ->
  Session.set 'graphToShow', {nodes:[],edges:[]}
  verts = verticesInsideGraphSON3(Session.get 'scriptResult')
  verts = _.uniq(verts,(item)->
    return item.id['@value'])
  edges = edgesInsideGraphSON3(Session.get 'scriptResult')
  vIDsInEdges = vertIDsInEdgesGraphSON3(edges)
  vIDsInResults = []
  vIDsInResults = (v.id['@value'] for v in verts)
  missingVIDs = _.difference vIDsInEdges, vIDsInResults
  if missingVIDs.length == 0
    return setGraphToShowGraphSON3 verts, edges
  bindings = {vIDs: missingVIDs}
  script = 'vIDs.collect{each-> g.V(each).next()}'
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if json.status.code == 204
          results = []
        else
          results = json.result.data
        addVertsToGraphToShowGraphSON3(v['@value'] for v in results['@value'])
        addEdgesToGraphToShowGraphSON3 edges
        addVertsToGraphToShowGraphSON3 verts
        gts = Session.get 'graphToShow'
        Session.set 'elementsInResults', gts
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in Vertex Retriever', script, bindings, (error,result)->
      addVertsToGraphToShowGraphSON3(result.results)
      addEdgesToGraphToShowGraphSON3 edges
      addVertsToGraphToShowGraphSON3 verts
      gts = Session.get 'graphToShow'
      Session.set 'elementsInResults', gts

window.addVertsToGraphToShow = (verts)->
  nodes = ({id: String(v.id),label: labelForVertex(v,Session.get 'keyForNodeLabel'), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(v), element:v} for v in verts)
  if window.visnetwork
    window.visnetwork.nodesHandler.body.data.nodes.update nodes
  if (Session.get 'graphToShow') == undefined
    Session.set 'graphToShow', {nodes:[],edges:[]}
  gts = Session.get 'graphToShow'
  gts.nodes=gts.nodes.concat nodes
  Session.set 'graphToShow',gts
  if gts.nodes.length + gts.edges.length > 0
    Session.set 'graphFoundInResults', true
  else
    Session.set 'graphFoundInResults', false

window.addEdgesToGraphToShow = (edges)->
  edges = ({id: String(e.id), label: e.label, from: String(e.outV), to: String(e.inV), title: titleForElement(e), element:e} for e in edges)
  if window.visnetwork
    window.visnetwork.edgesHandler.body.data.edges.update edges
  if (Session.get 'graphToShow') == undefined
    Session.set 'graphToShow', {nodes:[],edges:[]}
  gts = Session.get 'graphToShow'
  #console.log 'before=',gts
  gts.edges=gts.edges.concat edges
  #console.log 'after=',gts
  Session.set 'graphToShow',gts
  if gts.edges.length + gts.edges.length > 0
    Session.set 'graphFoundInResults', true
  else
    Session.set 'graphFoundInResults', false

window.setGraphToShow = (verts, edges)->
  keyForLabel = Session.get 'keyForNodeLabel'
  nodes = ({id: String(v.id),label: labelForVertex(v,keyForLabel), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(v), element:v} for v in verts)
  edges = ({id: String(e.id), label: e.label, from: String(e.outV), to: String(e.inV), title: titleForElement(e), element:e} for e in edges)
  g = {nodes: nodes, edges: edges}
  Session.set 'graphToShow',g
  if g.nodes.length + g.edges.length > 0
    Session.set 'graphFoundInResults', true
  else
    Session.set 'graphFoundInResults', false



window.addVertsToGraphToShowGraphSON3 = (verts)->
  nodes = []
  for v in verts
    v.type = 'vertex'
    node = {id: String(v.id['@value']),label: labelForVertexGraphSON3(v,Session.get 'keyForNodeLabel'), allowedToMoveX: true, allowedToMoveY: true, title: titleForElementGraphSON3(v), element:v}
    nodes.push node
  if window.visnetwork
    window.visnetwork.nodesHandler.body.data.nodes.update nodes
  if (Session.get 'graphToShow') == undefined
    Session.set 'graphToShow', {nodes:[],edges:[]}
  gts = Session.get 'graphToShow'
  gts.nodes=gts.nodes.concat nodes
  Session.set 'graphToShow',gts
  if gts.nodes.length + gts.edges.length > 0
    Session.set 'graphFoundInResults', true
  else
    Session.set 'graphFoundInResults', false

window.addEdgesToGraphToShowGraphSON3 = (edgesData)->
  edges = []
  for e in edgesData
    e.type = 'edge'
    edge = {id: String(e.id['@value']['relationId']), label: e.label, from: String(e.outV['@value']), to: String(e.inV['@value']), title: titleForElementGraphSON3(e), element:e}
    edges.push edge
  if window.visnetwork
    window.visnetwork.edgesHandler.body.data.edges.update edges
  if (Session.get 'graphToShow') == undefined
    Session.set 'graphToShow', {nodes:[],edges:[]}
  gts = Session.get 'graphToShow'
  #console.log 'before=',gts
  gts.edges=gts.edges.concat edges
  #console.log 'after=',gts
  Session.set 'graphToShow',gts
  if gts.edges.length + gts.edges.length > 0
    Session.set 'graphFoundInResults', true
  else
    Session.set 'graphFoundInResults', false

window.setGraphToShowGraphSON3 = (verts, edgesData)->
  keyForLabel = Session.get 'keyForNodeLabel'
  nodes = []
  for v in verts
    v.type = 'vertex'
    node = {id: String(v.id['@value']),label: labelForVertexGraphSON3(v,keyForLabel), allowedToMoveX: true, allowedToMoveY: true, title: titleForElementGraphSON3(v), element:v}
    nodes.push node
  edges = []
  for e in edgesData
    e.type = 'edge'
    edge = {id: String(e.id['@value']['relationId']), label: e.label, from: String(e.outV['@value']), to: String(e.inV['@value']), title: titleForElementGraphSON3(e), element:e}
    edges.push edge
  g = {nodes: nodes, edges: edges}
  Session.set 'graphToShow',g
  if g.nodes.length + g.edges.length > 0
    Session.set 'graphFoundInResults', true
  else
    Session.set 'graphFoundInResults', false



window.randomizeLayout = ()->
  g = Session.get 'graphToShow'
  for node in g.nodes
    node.x=chance.floating({min:0,max:100})
    node.y=chance.floating({min:0,max:100})
  Session.set 'graphToShow', g

verticesInside = (obj)->
  verts = []
  allObjectsInsideWithKeyValue verts, obj, 'type', 'vertex'
  return verts

edgesInside = (obj)->
  edges = []
  allObjectsInsideWithKeyValue edges,obj, 'type', 'edge'
  return edges

vertIDsInEdges = (edges)->
  edgeVertIDs = []
  edgeVertIDs.push edge.inV for edge in edges
  edgeVertIDs.push edge.outV for edge in edges
  return _.uniq(edgeVertIDs)

allObjectsInsideWithKeyValue = (foundArray, obj, key, value)->
  if (typeof obj == 'string') || (typeof obj == 'boolean') || (typeof obj == 'number') || (typeof obj == 'symbol') || (typeof obj == 'undefined') || ( obj == null)
    return []
  if Array.isArray(obj)  #its an array, recurse
    allObjectsInsideWithKeyValue(foundArray,subObj,key,value) for subObj in obj
  else   #its not an array, assume an object
    if obj[key] && obj[key]==value
      foundArray.push obj
    else  #recurse deeper
      allObjectsInsideWithKeyValue(foundArray,obj[okey],key,value) for okey in Object.keys(obj)
  return []

verticesInsideGraphSON3 = (obj)->
  verts = []
  allObjectsInsideWithKeyValueGraphSON3 verts, obj, '@type', 'g:Vertex'
  return verts

edgesInsideGraphSON3 = (obj)->
  edges = []
  allObjectsInsideWithKeyValueGraphSON3 edges,obj, '@type', 'g:Edge'
  return edges

vertIDsInEdgesGraphSON3 = (edges)->
  edgeVertIDs = []
  edgeVertIDs.push edge.inV['@value'] for edge in edges
  edgeVertIDs.push edge.outV['@value'] for edge in edges
  return _.uniq(edgeVertIDs)

allObjectsInsideWithKeyValueGraphSON3 = (foundArray, obj, key, value)->
  if (typeof obj == 'string') || (typeof obj == 'boolean') || (typeof obj == 'number') || (typeof obj == 'symbol') || (typeof obj == 'undefined') || ( obj == null)
    return []
  if Array.isArray(obj)  #its an array, recurse
    allObjectsInsideWithKeyValueGraphSON3(foundArray,subObj,key,value) for subObj in obj
  else   #its not an array, assume an object
    if obj[key] && obj[key]==value
      foundArray.push obj['@value']
    else  #recurse deeper
      allObjectsInsideWithKeyValueGraphSON3(foundArray,obj[okey],key,value) for okey in Object.keys(obj)
  return []

#********************* array splitter, used to be used to process batches of verts and edges due to GET length restrictions, no longer needed since moving to POST
chunks = (array, size) ->
  results = []
  while (array.length)
    results.push(array.splice(0, size))
  return results

retrieveVerticesForIDs = (ids, callback)->
  if ids.length == 0
    return
  bindings = {vIDs: ids}
  script = 'vIDs.collect{each-> g.V(each).next()}'
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if json.status.code == 204
          results = []
        else
          results = json.result.data
        callback(results)
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in Vertex Retriever', script, bindings, (error,result)->
      callback(result.results)


titleForElementGraphSON3 = (props)->
  if props.type == 'edge'
    id = props.id['@value']['relationId']
  else
    id = props.id['@value']
  userProps = userPropertiesForElementGraphSON3(props)
  sortedKeys = _.sortBy(_.keys(userProps), (e)->
    return e.toLocaleLowerCase()
  )
  html = '<div  class="vis-element-popup">'
  html = html + '<table style="width:200">'
  html = html+'<tr><th>'+props.type+': </th><th>'+id+'</th><tr>'
  html = html+'<tr><td>label: </td><td>'+props.label+'</td><tr>'
  for key in sortedKeys
    value = userProps[key]
    tr = '<tr><td>'+key+': </td><td>'+value+'</td></tr>'
    html = html + tr
  html = html + '</table>'
  html = html + '</div>'
  return html

titleForElement = (props)->
#console.log props
  userProps = userPropertiesForElement(props)
  sortedKeys = _.sortBy(_.keys(userProps), (e)->
    return e.toLocaleLowerCase()
  )
  html = '<div  class="vis-element-popup">'
  html = html + '<table style="width:200">'
  html = html+'<tr><th>'+props.type+': </th><th>'+props.id+'</th><tr>'
  html = html+'<tr><td>label: </td><td>'+props.label+'</td><tr>'
  for key in sortedKeys
    value = userProps[key]
    tr = '<tr><td>'+key+': </td><td>'+value+'</td></tr>'
    html = html + tr
  html = html + '</table>'
  html = html + '</div>'
  return html

popupDialogForElement = (localElement, elementType)->
  props = localElement.element
  userProps = userPropertiesForElement(props)
  sortedKeys = _.sortBy(_.keys(userProps), (e)->
    return e.toLocaleLowerCase()
  )
  id = props.id
  html = '<div  class="vis-element-popup">'
  html = html + '<table style="width:100%" class="propTableForElementID'+id+'" name="'+elementType+'">'
  addPropButton = '<a href="#" class="btn btn-default" id="'+id+'" title="Add property"><span class="glyphicon glyphicon-plus element-addProperty'+id+'"></span></a>'
  if elementType == 'vertex'
    cloneButton = '<a href="#" class="btn btn-default" id="'+id+'" title="Clone this Vertex"><span class="clone-vertex'+id+'">Clone</span></a>'
  else
    cloneButton = '<a href="#" class="btn btn-default" id="'+id+'" title="Clone this Edge"><span class="clone-edge'+id+'">Clone</span></a>'
  deletePropButton = '<a href="#" class="btn btn-default" title="Delete property"><span class="glyphicon glyphicon-minus element-deleteProperty'+id+'"></span></a>'
  copyPropButton = '<a href="#" class="btn btn-default" title="Copy property"><span class="glyphicon glyphicon-copy element-copyProperty'+id+'"></span></a>'
  pastePropButton = '<a href="#" class="btn btn-default" title="Paste property"><span class="glyphicon glyphicon-paste element-pasteProperty'+id+'"></span></a>'
  logButton = '<a href="#" class="btn btn-default" title="console.log the element"><span class="glyphicon glyphicon-share element-log'+id+'"></span></a>'
  pinItButton = '<input type="checkbox" class="vis-options-checkbox" id="pinItCheckBoxForId'+id+'" value="'+localElement.allowedToMoveX+'" onclick="pinVertex(\''+id+'\',this.value)"><span class="glyphicon glyphicon-pushpin"></span></a>'
  html = html+'<tr><th>Property:  </th><th>Value</th><th style="width:50">'+addPropButton+pastePropButton+logButton+'</th><tr>'
  tr = '<tr><td>id:  </td><td>'+id+'</td><td style="width:50">'+pinItButton+'</td><tr>'
  html = html + tr
  tr = '<tr><td>label:  </td><td>'+props.label+'</td><th style="width:50" id="'+id+'" value="'+elementType+'" name="'+key+'">'+cloneButton+'</th></tr>'
  html = html + tr
  for key in sortedKeys
    value = userProps[key]
    tr = '<tr><td>'+key+':  </td><td><input type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'.commitButtonForElementID'+id+'\').show()"></td><th style="width:100%" id="'+id+'" value="'+elementType+'" name="'+key+'">'+deletePropButton+copyPropButton+'</th></tr>'
    html = html + tr
  html = html + '</table>'
  html = html + '<button type="button" style="display: none" class="commitButtonForElementID'+id+'" onclick="updateElementProps(\''+id+'\',\''+elementType+'\')">Commit changes</button>'
  html = html + '</div>'
  return html

popupDialogForElementGraphSON3 = (localElement, elementType)->
  props = localElement.element
  userProps = userPropertiesForElementGraphSON3(props)
  sortedKeys = _.sortBy(_.keys(userProps), (e)->
    return e.toLocaleLowerCase()
  )
  if elementType == 'vertex'
    id = props.id['@value']
  else
    id = props.id['@value']['relationId']
  html = '<div  class="vis-element-popup">'
  html = html + '<table style="width:100%" class="propTableForElementID'+id+'" name="'+elementType+'">'
  if elementType == 'vertex'
    addPropButton = '<a href="#" class="btn btn-default" id="'+id+'" title="Add property"><span class="glyphicon glyphicon-plus element-addVertexPropertyGraphSON3'+id+'"></span></a>'
    cloneButton = '<a href="#" class="btn btn-default" id="'+id+'" title="Clone this Vertex"><span class="clone-vertex'+id+'">Clone</span></a>'
  else
    addPropButton = '<a href="#" class="btn btn-default" id="'+id+'" title="Add property"><span class="glyphicon glyphicon-plus element-addEdgePropertyGraphSON3'+id+'"></span></a>'
    cloneButton = '<a href="#" class="btn btn-default" id="'+id+'" title="Clone this Edge"><span class="clone-edge'+id+'">Clone</span></a>'
  deletePropButton = '<a href="#" class="btn btn-default" title="Delete property"><span class="glyphicon glyphicon-minus element-deleteProperty'+id+'"></span></a>'
  copyPropButton = '<a href="#" class="btn btn-default" title="Copy property"><span class="glyphicon glyphicon-copy element-copyProperty'+id+'"></span></a>'
  pastePropButton = '<a href="#" class="btn btn-default" title="Paste property"><span class="glyphicon glyphicon-paste element-pasteProperty'+id+'"></span></a>'
  logButton = '<a href="#" class="btn btn-default" title="console.log the element"><span class="glyphicon glyphicon-share element-log'+id+'"></span></a>'
  pinItButton = '<input type="checkbox" class="vis-options-checkbox" id="pinItCheckBoxForId'+id+'" value="'+localElement.allowedToMoveX+'" onclick="pinVertex(\''+id+'\',this.value)"><span class="glyphicon glyphicon-pushpin"></span></a>'
  html = html+'<tr><th>Property:  </th><th>Value</th><th style="width:50">'+addPropButton+pastePropButton+logButton+'</th><tr>'
  tr = '<tr><td>id:  </td><td>'+id+'</td><td style="width:50">'+pinItButton+'</td><tr>'
  html = html + tr
  tr = '<tr><td>label:  </td><td>'+props.label+'</td><th style="width:50px" id="'+id+'" value="'+elementType+'" name="'+key+'">'+cloneButton+'</th></tr>'
  html = html + tr
  for key in sortedKeys
    value = userProps[key]
    type = findJavaTypeForPropertyNamedGraphSON3(key,props,elementType)
    cacheOriginalPropertyTypeGraphSON3(elementType,id,key,type)
    typeSelector = buildTypeSelectorHTMLGraphSON3(id,key,type,elementType,'disabled')
    tr = '<tr><td>'+key+':  </td><td style="width:100%"><input style="width:100%" type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'.commitButtonForElementID'+id+'\').show()"></td><td style="width:100%" id="'+id+'" value="'+elementType+'" name="'+key+'">'+typeSelector+deletePropButton+copyPropButton+'</td></tr>'
    html = html + tr
  html = html + '</table>'
  html = html + '<button type="button" style="display: none" class="commitButtonForElementID'+id+'" onclick="updateElementPropsGraphSON3(\''+id+'\',\''+elementType+'\')">Commit changes</button>'
  html = html + '</div>'
  return html

cacheOriginalPropertyTypeGraphSON3 = (elementType,id,key,type)->
  if not window.ElementPropertyTypeChangeCacheForGraphSON3
    window.ElementPropertyTypeChangeCacheForGraphSON3 = {vertex:{},edge:{}}
  if not window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]
    window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id] = {originalTypes:{}, newTypes:{}}
  window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['originalTypes'][key]=type

propertyTypesChangedGraphSON3 = (elementType,id)->
  if window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['newTypes'] == {}
    return []
  changedTypes = {}
  newTypes = window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['newTypes']
  newTypeKeys = Object.keys(newTypes)
  for key in newTypeKeys
    origType = window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['originalTypes'][key]
    if origType != newTypes[key]
      changedTypes[key] = newTypes[key]
  return changedTypes

window.currentPropertyTypesGraphSON3 = (elementType,id)->
  currentTypes =  _.clone(window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['originalTypes'])
  for key in _.keys(window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['newTypes'])
    currentTypes[key] = window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['newTypes'][key]
  return currentTypes

findJavaTypeForPropertyNamedGraphSON3 = (propName, element, elementType)->
  if elementType == 'vertex'
    propVal = element.properties[propName][0]['@value']['value']
  else
    propVal = element.properties[propName]['@value']['value']
  if propVal['@type']
    gtype = propVal['@type']
    if gtype == "janusgraph:Geoshape"
      type = "Geoshape"
    else
      if gtype.slice(0,2) == "gx"
        type = gtype.slice(3)
      else
        type = gtype.slice(2)
  else
    type = 'Undef'
    if typeof propVal == 'string' then type = 'String'
    if typeof propVal == 'boolean' then type = 'Boolean'
    console.log typeof propVal, type
  return type


buildTypeSelectorHTMLGraphSON3 = (id,key,type,elementType, disabled)->
  valueLabelMap = {
    String: 'String'
    Char: 'Char'
    Boolean: 'Bool'
    Byte: 'Byte'
    Int32: 'Int32'
    Int64: 'Int64'
    Float: 'Float'
    Double: 'Double'
    Date: 'Date'
    Geoshape: 'Shape'
    UUID: 'UUID'
    Class: 'Class'
  }
  html = '<select class="typeSelectorFor'+id+'" '+disabled+' onchange="$(\'.commitButtonForElementID' + id + '\').show();window.changePropertyTypeGraphSON3(\''+elementType+'\',\''+id+'\',\''+key+'\',this.value)"   style="width:70px" >'
  for val in Object.keys(valueLabelMap)
    selected = ''
    if type == val
      selected = 'selected'
    option = '<option '+selected+' value="'+val+'">'+valueLabelMap[val]+'</option>'
    html = html + option
  html = html + '</select>'
  return html

window.turnOffTypeSelectorsForID = (id)->
  $('.typeSelectorFor'+id).attr('disabled', true)

window.changePropertyTypeGraphSON3 = (elementType,id,key,newType)->
  window.ElementPropertyTypeChangeCacheForGraphSON3[elementType][id]['newTypes'][key]=newType
  if elementType == 'vertex'
    visElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
    if not visElement.element.properties
      visElement.element['properties'] = {}
    if not visElement.element.properties[key]
      visElement.element.properties[key] = [{"@type": "g:VertexProperty", "@value":{"value":{"@type": typeStringForGraphSON3(newType)}}}]
    prop = visElement.element.properties[key][0]['@value']
  else
    visElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
    if not visElement.element.properties
      visElement.element['properties'] = {}
    if not visElement.element.properties[key]
      visElement.element.properties[key] = {"@type": "g:Property", "@value":{"value":{"@type": typeStringForGraphSON3(newType)}}}
    prop = visElement.element.properties[key]['@value']   #note there is a duplicate "key" here we are ignoring within the "value"
  prop['value']["@type"] = typeStringForGraphSON3(newType)


typeStringForGraphSON3 = (type)->
  prefix = 'g'
  if type == 'Char' then prefix = 'gx'
  if type == 'Byte' then prefix = 'gx'
  if type == 'Geoshape' then prefix = 'janusgraph'
  return prefix+':'+type



window.pinVertex = (id, value)->
  node = clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
  state = $('#pinItCheckBoxForId'+node.id).first().is(':checked')
  nds = window.visnetwork.nodesHandler.body.data.nodes.getDataSet()
  nds.update({id:node.id, physics: not state})

window.updateElementProps = (id,elementType)->
  if elementType == 'vertex'
    clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
  else
    clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
  props = {}
  originalProps = userPropertiesForElement(clientElement.element)
  $('.propForElementID'+id).each ()->   #scanning to get current values from web form
    props[$(this).attr("name")] = $(this).val()
  window.updatePropsForElement(elementType,id,props,originalProps)

window.updateElementPropsGraphSON3 = (id,elementType)->
  if elementType == 'vertex'
    clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
  else
    clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
  props = {}
  originalProps = userPropertiesForElementGraphSON3(clientElement.element)
  $('.propForElementID'+id).each ()->  #scanning to get current values from web form
    props[$(this).attr("name")] = $(this).val()
  window.updatePropsForElementGraphSON3(elementType,id,props,originalProps)


javaValueExpressionGraphSON3 = (element,key,value,type)->
  if typeof value == 'string'
    str = value
  else
    str = JSON.stringify(value)
  if type == 'String'
    expression = '"'+str+'"'
    return expression
  if type == 'Char'
    if str.length > 1
      alert('the value for property "'+key+'" should be between a single character (Char).  Truncating "'+str+'" to "'+str.slice(0,1)+'"')
    if str.length = 0
      alert('the value for property "'+key+'" should be between a single character (Char).  This string is empty.')
    expression = '"'+str.slice(0,1)+'"'
    return expression
  if type == 'Byte'
# a byte in Java/Groovy is short between -127 and 127
    num = Number.parseInt(str)
    if num < -127 or num >127
      alert('the value for property "'+key+'" should be between -127 and 127 (Byte).  This in not a byte: '+str)
    expression = num.toString()+' as byte'
    return expression
  if type == 'Int32'
    num = Number.parseInt(str)
    if isNaN(num)
      alert('the value for property "'+key+'" should be an integer (Int32).  This is not a number: '+str)
    expression = num.toString()+' as Integer'
    return expression
  if type == 'Int64'
    num = Number.parseInt(str)
    if isNaN(num)
      alert('the value for property "'+key+'" should be an integer (Int64).  This is not a number: '+str)
    expression = num.toString()+' as Long'
    return expression
  if type == 'Float'
    num = Number.parseFloat(str)
    if isNaN(num)
      alert('the value for property "'+key+'" should be a float (Float).  This is not a number: '+str)
    expression = num.toString()+' as Float'
    return expression
  if type == 'Double'
    num = Number.parseFloat(str)
    if isNaN(num)
      alert('the value for property "'+key+'" should be a double-precision float (Double).  This is not a number: '+str)
    expression = num.toString()+' as Double'
    return expression
  if type == 'Boolean'
    str = str.toLowerCase()
    if str != 'true' and str != 'false'
      alert('the value for property "'+key+'" should be true or false (Boolean).  This is neither: '+str)
    expression = str
    return expression
  if type == 'Date'
    num = Number.parseFloat(str)
    if isNaN(num)  
      alert('the value for property "'+key+'" should be integer milliseconds since 1-1-1970 (Date).  This is not a number of milliseconds: '+str)
    expression = 'new Date('+num.toString()+')'
    return expression
  if type == 'UUID'
    if str.length != 36
      alert('the value for property "'+key+'" should be a 36 character string like "13971916-83be-4b52-9d74-f478d45e2dcd" (UUID).  This is not long enough: '+str)
    expression = 'UUID.fromString("'+str+'")'
    return expression
  if type == 'Class'
    if str.length == 0
      alert('the value for property "'+key+'" should be a string like "org.apache.tinkerpop.gremlin.structure.Vertex" or "Vertex" (Class).  This is string is empty '+str)
    expression = str
    return expression
  if type == 'Geoshape'
    if not ((str.slice(0,"Geoshape.circle".length) == "Geoshape.circle") or (str.slice(0,"POINT".length) == "POINT") or (str.slice(0,"POLYGON".length) == "POLYGON"))
      alert('the value for property "'+key+'" should be a string like "POINT (...)" or "POLYGON (...)" etc or "Geoshape.circle(...)" (Geoshape).  This is string is neither: '+str)
    if str.slice(0,"Geoshape.circle".length) == "Geoshape.circle"
      expression = str
    else
      expression = 'Geoshape.fromWkt("'+str+'")'
    console.log expression
    return expression


geoshapeGraphSON3ToJava = (g3)->
  if g3['coordinates']   #we have a point
    pts = g3['coordinates']
    ptstrs = (pt.toString() for pt in pts)
    if pts.length == 2 then mod = ''
    if pts.length == 3 then mod = 'Z'  #note we are ignoring the solo M possibility
    if pts.length == 4 then mod = 'ZM'
    str = 'POINT ('
    for ptstr in ptstrs
      str = str + ptstr + ' '
    str = str + ')'
    return str
  if g3['geometry']   #we have a geometric object
    val = g3['geometry']['@value']
    type = val[1]
    if type == 'Circle'
      centerCoords = valueListFromGraphSON3(val[3])
      radius = valueFromGraphSON3(val[5])
      str = 'Geoshape.circle('+centerCoords[0].toString()+','+centerCoords[1].toString()+','+radius.toString()+')'
      return str
    # otherwise we have a WKT version
    wkt = geoshapeGeometryGraphSON3ToWKT(val)
    return wkt

geoshapeGeometryGraphSON3ToWKT = (val)->
  #val = g3['@value']['geometry']['@value'] or g3['@value']['@value'] in the GeoCollection geometries case
  if val['@type'] then val = val['@value']   #ugly hack for the geocollection case
  type = val[1]
  if type == 'Point'
    str = 'POINT '     #ignoring Z and M and MZ options for now, only 2D points supported here
    list = wktValueListFromGraphSON3(val[3],'spaces',false)
    str = str + list
    return str
  if type == 'Polygon'
    str = 'POLYGON '
    list = wktValueListFromGraphSON3(val[3],'commas',false)
    str = str + list
    return str
  if type == 'LineString'
    str = 'LINESTRING '
    list = wktValueListFromGraphSON3(val[3],'commas',false)
    str = str + list
    return str
  if type == 'MultiPoint'
    str = 'MULTIPOINT '
    list = wktValueListFromGraphSON3(val[3],'commas',false)
    str = str + list
    return str
  if type == 'MultiLineString'
    str = 'MULTILINESTRING '
    list = wktValueListFromGraphSON3(val[3],'commas',false)
    str = str + list
    return str
  if type == 'MultiPolygon'
    str = 'MULTIPOLYGON '
    list = wktValueListFromGraphSON3(val[3],'commas',false)
    str = str + list
    return str
  if type == 'GeometryCollection'
    str = 'GEOMETRYCOLLECTION '
    list = wktValueListFromGraphSON3(val[3],'commas',true)
    str = str + list
    return str


valueListFromGraphSON3 = (g3)->
  if g3['@type'] != 'g:List' then debugger
  inList = g3['@value']
  outList = []
  for item in inList
    if item['@type'] == 'g:List'   #have a nested list so recurse
      outItem = valueListFromGraphSON3(item)
    else
      if item['@type'] == 'g:Map'   #have a geometry object
        outItem = geoshapeGeometryGraphSON3ToWKT(item)
      else
        if item['@type'] and item['@type'] == 'g:List'
          outItem = valueListFromGraphSON3(item)
        else
          outItem = item['@value']
    outList.push(outItem)
  return outList


wktValueListFromGraphSON3 = (g3,seps,geocol)->
  list = valueListFromGraphSON3(g3)
  return wktValueListFromValueList(list,seps,geocol)

wktValueListFromValueList = (list,seps,geocol)->
  if seps == 'spaces'
    sep = ' '
  else
    sep =','
  origSep = sep
  str = '('
  for item in list
    if item == undefined then debugger
    if Array.isArray(item)
      itemstr = wktValueListFromValueList(item,seps)
    else
      if item['@type'] and (item['@type'] == 'g:List')
        itemstr = wktValueListFromGraphSON3(item,seps)
      else
        if item['@type'] and (item['@type'] == 'g:List')
          itemstr = wktValueListFromGraphSON3(item,seps)
        else
          itemstr = item.toString()
          sep = ' '
    if geocol
      str = str  + itemstr + ','
    else
      str = str  + itemstr + sep
    sep = origSep
  str = str.slice(0,-1)
  str = str + ')'
  return str


valueFromGraphSON3 = (g3)->
  #any other type is assumed to be a number and ok to use value directly
  return g3['@value']


window.updatePropsForElementGraphSON3 = (elementType, id, newProps, oldProps) ->
  $('.commitButtonForElementID'+id).hide()
  keys2Delete = []
  for key in _.keys(oldProps)
    if newProps[key] == undefined
      keys2Delete.push(key)
  if elementType == 'vertex'
    clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
  else
    clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
  script = ''
  if keys2Delete.length > 0
  #$(".propTableForElementID"+id).parent().parent().parent().height($(".propTableForElementID"+id).parent().parent().parent().height()-28)
    if elementType == "vertex"
      script = script + 'keys2Delete.each { g.V(vID).properties(it).drop()}'
    else
      script = script + 'keys2Delete.each { g.E(vID).properties(it).drop()}'
    bindings = {keys2Delete: keys2Delete, vID: id}
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        console.log msg
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
          else
            results = json.result.data
          for key2Delete in keys2Delete
            clientElement.element.properties = _.omit clientElement.element.properties, key2Delete
            clientElement.title = titleForElementGraphSON3(clientElement.element)
            if elementType == 'vertex'
              window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
            else
              window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
      #set up request
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in property remover', script, bindings,(error,result)->
        if result.success == true
          for key2Delete in keys2Delete
            clientElement.element.properties = _.omit clientElement.element.properties, key2Delete
            clientElement.title = titleForElementGraphSON3(clientElement.element)
            if elementType == 'vertex'
              window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
            else
              window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
        else
          alert "Graph update failed.  Nothing changed.  Maybe try again?"
  changedProps = {}
  for key in _.keys(newProps)
    if oldProps[key] == undefined
      changedProps[key] = newProps[key]
    else
      if newProps[key].toString() != oldProps[key].toString()
        changedProps[key] = newProps[key]
  changedTypes = propertyTypesChangedGraphSON3(elementType,id)
  propTypes = window.currentPropertyTypesGraphSON3(elementType,id)
  if (not $.isEmptyObject(changedProps)) or (Object.keys(changedTypes).length > 0)
    if elementType == 'vertex'
      script = 'v=g.V('+id+').next();'
    else
      script = 'v=g.E("'+id+'").next();'
    allKeys = _.uniq(_.union(_.keys(changedProps), _.keys(changedTypes)))
    for key in allKeys
      if changedProps[key]
        propVal = changedProps[key]
      else
        propVal = oldProps[key]
      if changedTypes[key]
        propType = changedTypes[key]
      else
        propType = propTypes[key]
      script = script + 'v.property("'+key+'",'+javaValueExpressionGraphSON3(clientElement.element,key,propVal,propType)+');'
    script = script + 'v '
    console.log script
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
          else
            results = json.result.data
          if elementType == 'vertex'
            clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
          else
            clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
          clientElement.element = results['@value'][0]['@value']
          clientElement.element.type = elementType
          turnOffTypeSelectorsForID(id)
          clientElement.title = titleForElementGraphSON3(clientElement.element)
          cacheOriginalPropertyTypeGraphSON3(elementType,id,key,propType)
          #console.log "clientElement=",clientElement
          delete clientElement.x
          delete clientElement.y
          if elementType == 'vertex'
            window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
          else
            window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
          getLabelSets()
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: {}, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in property updater', script, (error,result)->
        if result.success == true
          if elementType == 'vertex'
            clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
          else
            clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
          clientElement.element = result.results[0]
          clientElement.title = titleForElementGraphSON3(clientElement.element)
          #console.log "clientElement=",clientElement
          delete clientElement.x
          delete clientElement.y
          if elementType == 'vertex'
            window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
          else
            window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
          getLabelSets()
        else
          alert "Graph update failed.  Nothing changed.  Maybe try again?"

window.updatePropsForElement = (elementType, id, newProps, oldProps) ->
  $('.commitButtonForElementID'+id).hide()
  keys2Delete = []
  for key in _.keys(oldProps)
    if newProps[key] == undefined
      keys2Delete.push(key)
  if elementType == 'vertex'
    clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
  else
    clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
  script = ''
  if keys2Delete.length > 0
#$(".propTableForElementID"+id).parent().parent().parent().height($(".propTableForElementID"+id).parent().parent().parent().height()-28)
    if elementType == "vertex"
      script = script + 'keys2Delete.each { g.V(vID).properties(it).drop()}'
    else
      script = script + 'keys2Delete.each { g.E(vID).properties(it).drop()}'
    bindings = {keys2Delete: keys2Delete, vID: id}
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        console.log msg
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
          else
            results = json.result.data
          for key2Delete in keys2Delete
            clientElement.element.properties = _.omit clientElement.element.properties, key2Delete
            clientElement.title = titleForElement(clientElement.element)
            if elementType == 'vertex'
              window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
            else
              window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
      #set up request
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in property remover', script, bindings,(error,result)->
        if result.success == true
          for key2Delete in keys2Delete
            clientElement.element.properties = _.omit clientElement.element.properties, key2Delete
            clientElement.title = titleForElement(clientElement.element)
            if elementType == 'vertex'
              window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
            else
              window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
        else
          alert "Graph update failed.  Nothing changed.  Maybe try again?"
  changedProps = {}
  for key in _.keys(newProps)
    if oldProps[key] == undefined
      changedProps[key] = newProps[key]
    else
      if newProps[key].toString() != oldProps[key].toString()
        changedProps[key] = newProps[key]
  if not $.isEmptyObject(changedProps)
    if elementType == 'vertex'
      script = 'v=g.V('+id+').next();'
    else
      script = 'v=g.E("'+id+'").next();'
    for key in _.keys(changedProps)
      script = script + 'v.property("'+key+'","'+changedProps[key]+'");'
    script = script + 'v '
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
          else
            results = json.result.data
          if elementType == 'vertex'
            clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
          else
            clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
          clientElement.element = results[0]
          clientElement.title = titleForElement(clientElement.element)
          #console.log "clientElement=",clientElement
          delete clientElement.x
          delete clientElement.y
          if elementType == 'vertex'
            window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
          else
            window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
          getLabelSets()
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: {}, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in property updater', script, (error,result)->
        if result.success == true
          if elementType == 'vertex'
            clientElement = window.visnetwork.nodesHandler.body.data.nodes._data[id]
          else
            clientElement = window.visnetwork.edgesHandler.body.data.edges._data[id]
          clientElement.element = result.results[0]
          clientElement.title = titleForElement(clientElement.element)
          #console.log "clientElement=",clientElement
          delete clientElement.x
          delete clientElement.y
          if elementType == 'vertex'
            window.visnetwork.nodesHandler.body.data.nodes.update [clientElement], []
          else
            window.visnetwork.edgesHandler.body.data.edges.update [clientElement], []
          getLabelSets()
        else
          alert "Graph update failed.  Nothing changed.  Maybe try again?"

getLabelSets = () ->
  nodes = _.values(window.visnetwork.nodesHandler.body.data.nodes._data)
  edges = _.values(window.visnetwork.edgesHandler.body.data.edges._data)
  nodeLabels = _.uniq(node.element.label for node in nodes)
  edgeLabels = _.uniq(edge.element.label for edge in edges)
  nodePropKeys = []
  edgePropKeys = []
  for node in nodes
    if node.element.properties
      nodePropKeys = _.union(nodePropKeys,_.keys(node.element.properties))
  for edge in edges
    if edge.element.properties
      edgePropKeys = _.union(edgePropKeys,_.keys(edge.element.properties))
  sorted = _.sortBy(nodeLabels, (it)->
    it
  )
  Session.set('vertexLabelSet',sorted)
  sorted = _.sortBy(edgeLabels, (it)->
    it
  )
  Session.set 'edgeLabelSet',sorted
  sorted = _.sortBy(_.union(nodePropKeys,edgePropKeys), (it)->
    it
  )
  Session.set('vertexPropertyNames',sorted)


window.updateVertexLabelBootBox = (ctxt) ->
  $('input.bootbox-input.bootbox-input-text.form-control')[0].value = ctxt.value


addVertToGraph = (nodeData, callback) ->
#nodeData is the vis.js object for its newly created node on the client
  keyForLabel = Session.get 'keyForNodeLabel'
  labels = Session.get 'vertexLabelSet'
  labelSelectorHTML = '<select onchange="window.updateVertexLabelBootBox(this)">'
  optionHTML = '<option>Select a vertex label</option>'
  labelSelectorHTML = labelSelectorHTML + optionHTML
  for label in labels
    do(label)->
      optionHTML = '<option>'+label+'</option>'
      labelSelectorHTML = labelSelectorHTML + optionHTML
  labelSelectorHTML = labelSelectorHTML + '</select>'
  label = ""
  bootbox.prompt("<p>Enter the label for this new vertex or choose one of these "+labelSelectorHTML+"</p><p>Vertex labels are immutable (can't be changed), so choose wisely.</p>", (result)->
    label = result
    if label == null || label == ""
#alert "Vertices must have labels, adding vertex aborted"
      callback(null)
      return
    script = 'g.addV("'+label+'")'
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
            nodeData = []
          else
            if window.UsingGraphSON3
              results = json.result.data['@value']
              v = results[0]['@value']
              v.type = 'vertex'
            else
              results = json.result.data
              v = results[0]
            if (Session.get 'tinkerPopVersion') == '3'
              nodeData.id = String(v.id)
            else
              nodeData.id = String(v._id)
            nodeData.allowedToMoveX = true
            nodeData.allowedToMoveY = true
            if window.UsingGraphSON3
              nodeData.id = v.id['@value']
              nodeData.title = titleForElementGraphSON3(v)
              nodeData.label = labelForVertexGraphSON3(v,keyForLabel)
            else
              nodeData.title = titleForElement(v)
              nodeData.label = labelForVertex(v,keyForLabel)
            nodeData.element = v
            nodeData.physics = false   # start out pinned
            #console.log nodeData,v
          getLabelSets()
          callback(nodeData)
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: {}, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in property updater', script, (error,result)->
        if result.success == true
          if window.UsingGraphSON3
            v = result.results['@value']['@value'][0]
            v.type = 'vertex'
          else
            v = result.results[0]
          if (Session.get 'tinkerPopVersion') == '3'
            nodeData.id = String(v.id)
          else
            nodeData.id = String(v._id)
            if window.UsingGraphSON3
              nodeData.title = titleForElementGraphSON3(v)
              nodeData.label = labelForVertexGraphSON3(v,keyForLabel)
            else
              nodeData.title = titleForElement(v)
              nodeData.label = labelForVertex(v,keyForLabel)
          nodeData.allowedToMoveX = true
          nodeData.allowedToMoveY = true
          nodeData.element = v
          nodeData.physics = false   # start out pinned
          #console.log nodeData,v
          getLabelSets()
          callback(nodeData)
        else
          alert "Graph update failed.  Nothing changed"
  )

cloneVertToGraph = (id) ->
#id is the tinkerpop id for the vertex to be cloned
  node2Clone = window.visnetwork.body.data.nodes._data[id]
  vertex2Clone = node2Clone.element
  script = 'g.addV("'+vertex2Clone.label+'")'
  v2c = _.clone(vertex2Clone)
  delete v2c.type
  delete v2c.label
  delete v2c.id
  if v2c['properties']
    for key in Object.keys(v2c.properties)
      script = script + '.property("'+key+'","'+v2c.properties[key][0].value+'")'
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if window.UsingGraphSON3
          results = json.result.data['@value']
          v = results[0]['@value']
          v.type = 'vertex'
          newNode = {id: String(v.id['@value']),label: labelForVertexGraphSON3(v,Session.get('keyForNodeLabel')),allowedToMoveX: true, allowedToMoveY: true, title: titleForElementGraphSON3(v), element:v}
        else
          results = json.result.data
          v = results[0]
          newNode = {id: String(v.id),label: labelForVertex(v,Session.get('keyForNodeLabel')),allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(v), element:v}
        window.visnetwork.nodesHandler.body.data.nodes.add newNode
        oldLoc = (window.visnetwork.getPositions([node2Clone.id]))[node2Clone.id]
        window.visnetwork.moveNode(newNode.id,oldLoc.x + 50,oldLoc.y + 50)
        window.visnetwork.setSelection({nodes: [newNode.id], edges: []},{unselectedAll: false, highlightEdges: false})
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: {}, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Vertex cloner', script, (error,result)->
      if result.success == true
        if window.UsingGraphSON3
          results = json.result.data['@value']
          v = results[0]['@value']
          v.type = 'vertex'
          newNode = {id: String(v.id['@value']),label: labelForVertexGraphSON3(v,Session.get('keyForNodeLabel')),allowedToMoveX: true, allowedToMoveY: true, title: titleForElementGraphSON3(v), element:v}
        else
          v = result.results[0]
          newNode = {id: String(v.id),label: labelForVertex(v,Session.get('keyForNodeLabel')),allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(v), element:v}
        window.visnetwork.nodesHandler.body.data.nodes.add newNode
        oldLoc = (window.visnetwork.getPositions([node2Clone.id]))[node2Clone.id]
        window.visnetwork.moveNode(newNode.id,oldLoc.x + 50,oldLoc.y + 50)
        window.visnetwork.setSelection({nodes: [newNode.id], edges: []},{unselectedAll: false, highlightEdges: false})
      else
        alert "Graph update failed.  Nothing changed: "+script



arrayFromGraphSON3List = (g3)->
  if not g3['@type'] == 'g:List' then debugger
  return g3['@value']

objectFromGraphSON3Map = (g3)->
  if not g3['@type'] == 'g:Map' then debugger
  list = g3['@value']    #pairs in the list == key/values in an object
  obj = {}
  for x in [0...list.length-1] by 2
    if list[x]['@type'] == "janusgraph:RelationIdentifier"
      key = list[x]['@value']['relationId']
    else
      key = list[x]['@value']
    obj[key] = list[x+1]['@value']
  return obj





#-------------for use from Context UI-----------------------
invertSelections = ()->
#swap unselected with selected
  allNodes = (node.id for node in window.visnetwork.nodesHandler.body.data.nodes.get())
  allEdges = (edge.id for edge in window.visnetwork.nodesHandler.body.data.edges.get())
  selections = window.visnetwork.getSelection()
  selectedNodes = selections.nodes
  selectedEdges = selections.edges
  nodes2Select = _.difference(allNodes,selectedNodes)
  edges2Select = _.difference(allEdges,selectedEdges)
  window.visnetwork.setSelection({nodes: nodes2Select, edges: edges2Select})

selectAll = ()->
#select all local nodes and edges
  nodes2Select = (node.id for node in window.visnetwork.nodesHandler.body.data.nodes.get())
  edges2Select = (edge.id for edge in window.visnetwork.nodesHandler.body.data.edges.get())
  window.visnetwork.setSelection({nodes: nodes2Select, edges: edges2Select},{unselectedAll: true, highlightEdges: false})

selectNone = ()->
#deselect all local element
  window.visnetwork.unselectAll()

layoutSelectionsInCircle = ()->
  elementIDs = window.visnetwork.getSelection()
  nds = window.visnetwork.nodesHandler.body.data.nodes.getDataSet()
  eds = window.visnetwork.edgesHandler.body.data.edges.getDataSet()
  for nodeID in elementIDs.nodes
    nds.update({id:nodeID, physics: false})
#for edgeID in elementIDs.edges
#  eds.update({id:edgeID, physics: false})

pinSelections = ()->
  elementIDs = window.visnetwork.getSelection()
  nds = window.visnetwork.nodesHandler.body.data.nodes.getDataSet()
  eds = window.visnetwork.edgesHandler.body.data.edges.getDataSet()
  for nodeID in elementIDs.nodes
    nds.update({id:nodeID, physics: false})
#for edgeID in elementIDs.edges
#  eds.update({id:edgeID, physics: false})

unpinSelections = ()->
  elementIDs = window.visnetwork.getSelection()
  nds = window.visnetwork.nodesHandler.body.data.nodes.getDataSet()
  eds = window.visnetwork.edgesHandler.body.data.edges.getDataSet()
  for nodeID in elementIDs.nodes
    nds.update({id:nodeID, physics: true})
  #for edgeID in elementIDs.edges
  #  eds.update({id:edgeID, physics: true})

inspectSelections = ()->
  elementIDs = window.visnetwork.getSelection()
  for nodeID in elementIDs.nodes
    elementType = 'vertex'
    element = window.visnetwork.nodesHandler.body.data.nodes.get(nodeID)
    window.popupPropertyEditor(element, elementType)
  for edgeID in elementIDs.edges
    elementType = 'edge'
    element = window.visnetwork.edgesHandler.body.data.edges.get(edgeID)
    window.popupPropertyEditor(element, elementType)

shareGremlinCodeForIngestion  = ()->
  script = scriptForGeneralIngestionFindOrCreate()
  wnd = window.open("", "", "_blank")
  title = "<title>Gremlin code to use with JSON bindings to programmatically add elements</title>"
  wnd.document.write(title+"<pre><code>"+script+"</code></pre>")

inputGremlinCodeForIngestion  = ()->
  bindings = JSON.parse prompt('Paste bindings JSON here')
  console.log bindings
  if window.UsingGraphSON3
    addElementsFromBindingsJSONGraphSON3(bindings)
  else
    addElementsFromBindingsJSON(bindings)

generateJSONBindingsForSelections  = ()->
  elementIDs = window.visnetwork.getSelection()
  vertsJSON = []
  styles = {}
  for nodeID in elementIDs.nodes
    node = window.visnetwork.nodesHandler.body.data.nodes.get(nodeID)
    vertsJSON.push node.element
    styles[nodeID] = _.omit(node, ['element','id','x','y','label','physics','allowedToMoveX','allowedToMoveY','title'])
  edgesJSON = []
  for edgeID in elementIDs.edges
    edge = window.visnetwork.edgesHandler.body.data.edges.get(edgeID)
    edgesJSON.push edge.element
    styles[edgeID] = _.omit(edge, ['element','id','from','to','label','title'])

  bindings =
    "verts2FindOrCreate": []
    "vertsJSON": vertsJSON
    "edgesJSON": edgesJSON
    "transactionContext": "ingesting a subgraph",
    "locations":window.visnetwork.getPositions(elementIDs.nodes)
    "styles": styles
  ###
    link = document.createElement('a')
    link.download = 'bindings-for-tinkertools-selections.json'
    blob = new Blob([JSON.stringify(bindings, null, 2)], {type: 'text/plain'})
    link.href = window.URL.createObjectURL(blob)
    link.click()
  ###
  wnd = window.open("", "", "_blank")
  title = "<title>JSON bindings for selected graph elements</title>"
  wnd.document.write(title+"<pre><code>"+JSON.stringify(bindings, null, 2)+"</code></pre>")


spawnToQuikVis = () ->
  allNodes = window.visnetwork.getSelectedNodes()
  allEdges = window.visnetwork.getSelectedEdges()
  positions = window.visnetwork.getPositions(allNodes)
  spawnTheseToQuikVis("selections",allNodes,allEdges,positions)

spawnTheseToQuikVis = (subtitle, allNodes,allEdges, positions) ->
  script = "vertIDs = "+JSON.stringify(allNodes)+"\n"
  script = script + "edgeIDs = "+JSON.stringify(allEdges)+"\n"
  script = script + "if (vertIDs != []) {vs = g.V(vertIDs).toList()}else{vs=[]}"+"\n"
  script = script + "if (edgeIDs != []) {es = g.E(edgeIDs).toList()}else{es=[]}"+"\n"
  script = script + "[vs,es]"+"\n"
  tinkertoolsServerURL = (Meteor.absoluteUrl()).slice(0,-1)
  if (tinkertoolsServerURL.slice(-5) == ':3000')
  else
    tinkertoolsServerURL = tinkertoolsServerURL + ':3000'
  url = tinkertoolsServerURL+"/quikvis?serverURL="+Session.get('serverURL')
  url = url + '&width="auto"'
  url = url + '&height="1000px"'
  url = url + "&graphName=the default graph"
  url = url + "&scripts="
  specs = JSON.stringify([{title:'Show elements',script: script}])
  url = url + encodeURIComponent(specs)
  url = url + "&positions="+JSON.stringify(positions)
  wnd = window.open("", "", "_blank")
  title = "<title>Spawned "+subtitle+" from Server: "+(Session.get 'serverURL')+"</title>"
  wnd.document.write(title+"<div></div><h4>From Server: "+(Session.get 'serverURL')+"  Script used</h4><textarea rows='1' cols='150'>"+script+"</textarea></div><iframe width='100%' height='100%' src='"+url+"'>")

spawnAllToQuikVis = () ->
  allNodes = (node.id for node in window.visnetwork.nodesHandler.body.data.nodes.getDataSet().get())
  allEdges = (edge.id for edge in window.visnetwork.edgesHandler.body.data.edges.getDataSet().get())
  positions = window.visnetwork.getPositions(allNodes)
  spawnTheseToQuikVis("graph",allNodes,allEdges,positions)


inspectNone = ()->
  $(".ui-dialog").detach()

hideSelections1 = ()->
  elementIDs = window.visnetwork.getSelection()
  nodes2Hide = window.visnetwork.body.data.nodes.getDataSet().get(elementIDs.nodes)
  edges2Hide = window.visnetwork.body.data.edges.getDataSet().get(elementIDs.edges)
  window.hidden1 = if window.hidden1 then window.hidden1 else {nodes:[],edges:[], positions:{}}
  #pin nodes
  for node in nodes2Hide
    node.physics = false
  #unpin edges
  for edge in edges2Hide
    edge.physics = true
  window.hidden1.nodes = _.union window.hidden1.nodes, nodes2Hide
  window.hidden1.edges = _.union window.hidden1.edges, edges2Hide
  window.hidden1.positions = _.extend window.hidden1.positions, window.visnetwork.getPositions(elementIDs.nodes)
  window.visnetwork.body.data.edges.getDataSet().remove(elementIDs.edges)
  window.visnetwork.body.data.nodes.getDataSet().remove(elementIDs.nodes)
  window.visnetwork.setSelection({ nodes: [], edges: []})
  $(".context-hideSelections1").text(""+window.hidden1.nodes.length+"v,"+window.hidden1.edges.length+"e")

unhideSelections1 = ()->
  window.hidden1 = if window.hidden1 then window.hidden1 else {nodes:[],edges:[], positions:{}}
  window.visnetwork.body.data.nodes.getDataSet().add window.hidden1.nodes
  window.visnetwork.body.data.edges.getDataSet().add window.hidden1.edges
  window.visnetwork.setSelection({ nodes: (each.id for each in window.hidden1.nodes), edges: (each.id for each in window.hidden1.edges)})
  for node in window.hidden1.nodes
    oldLoc = window.hidden1.positions[node.id]
    window.visnetwork.moveNode(node.id,oldLoc.x,oldLoc.y)
  window.hidden1 = {nodes:[],edges:[], positions:{}}
  $(".context-hideSelections1").text("Hide1")

spawnHidden1 = ()->
  hiddenNodes = (each.id for each in window.hidden1.nodes)
  hiddenEdges = (each.id for each in window.hidden1.edges)
  spawnTheseToQuikVis("contents of hidden buffer 1", hiddenNodes,hiddenEdges,window.hidden1.positions)


hideSelections2 = ()->
  elementIDs = window.visnetwork.getSelection()
  nodes2Hide = window.visnetwork.body.data.nodes.getDataSet().get(elementIDs.nodes)
  edges2Hide = window.visnetwork.body.data.edges.getDataSet().get(elementIDs.edges)
  window.hidden2 = if window.hidden2 then window.hidden2 else {nodes:[],edges:[], positions:{}}
  #pin nodes
  for node in nodes2Hide
    node.physics = false
  #unpin edges
  for edge in edges2Hide
    edge.physics = true
  window.hidden2.nodes = _.union window.hidden2.nodes, nodes2Hide
  window.hidden2.edges = _.union window.hidden2.edges, edges2Hide
  window.hidden2.positions = _.extend window.hidden2.positions, window.visnetwork.getPositions(elementIDs.nodes)
  window.visnetwork.body.data.edges.getDataSet().remove(elementIDs.edges)
  window.visnetwork.body.data.nodes.getDataSet().remove(elementIDs.nodes)
  window.visnetwork.setSelection({ nodes: [], edges: []})
  $(".context-hideSelections2").text(""+window.hidden2.nodes.length+"v,"+window.hidden2.edges.length+"e")

unhideSelections2 = ()->
  window.hidden2 = if window.hidden2 then window.hidden2 else {nodes:[],edges:[], positions:{}}
  window.visnetwork.body.data.nodes.getDataSet().add window.hidden2.nodes
  window.visnetwork.body.data.edges.getDataSet().add window.hidden2.edges
  window.visnetwork.setSelection({ nodes: (each.id for each in window.hidden2.nodes), edges: (each.id for each in window.hidden2.edges)})
  for node in window.hidden2.nodes
    oldLoc = window.hidden2.positions[node.id]
    window.visnetwork.moveNode(node.id,oldLoc.x,oldLoc.y)
  window.hidden2 = {nodes:[],edges:[], positions:{}}
  $(".context-hideSelections2").text("Hide2")
window.hidden2 = {nodes:[],edges:[], positions:{}}

spawnHidden2 = ()->
  hiddenNodes = (each.id for each in window.hidden2.nodes)
  hiddenEdges = (each.id for each in window.hidden2.edges)
  spawnTheseToQuikVis("contents of hidden buffer 2", hiddenNodes,hiddenEdges,window.hidden2.positions)

hideSelections3 = ()->
  elementIDs = window.visnetwork.getSelection()
  nodes2Hide = window.visnetwork.body.data.nodes.getDataSet().get(elementIDs.nodes)
  edges2Hide = window.visnetwork.body.data.edges.getDataSet().get(elementIDs.edges)
  window.hidden3 = if window.hidden3 then window.hidden3 else {nodes:[],edges:[], positions:{}}
  #pin nodes
  for node in nodes2Hide
    node.physics = false
  #unpin edges
  for edge in edges2Hide
    edge.physics = true
  window.hidden3.nodes = _.union window.hidden3.nodes, nodes2Hide
  window.hidden3.edges = _.union window.hidden3.edges, edges2Hide
  window.hidden3.positions = _.extend window.hidden3.positions, window.visnetwork.getPositions(elementIDs.nodes)
  window.visnetwork.body.data.edges.getDataSet().remove(elementIDs.edges)
  window.visnetwork.body.data.nodes.getDataSet().remove(elementIDs.nodes)
  window.visnetwork.setSelection({ nodes: [], edges: []})
  $(".context-hideSelections3").text(""+window.hidden3.nodes.length+"v,"+window.hidden3.edges.length+"e")

unhideSelections3 = ()->
  window.hidden3 = if window.hidden3 then window.hidden3 else {nodes:[],edges:[], positions:{}}
  window.visnetwork.body.data.nodes.getDataSet().add window.hidden3.nodes
  window.visnetwork.body.data.edges.getDataSet().add window.hidden3.edges
  window.visnetwork.setSelection({ nodes: (each.id for each in window.hidden3.nodes), edges: (each.id for each in window.hidden3.edges)})
  for node in window.hidden3.nodes
    oldLoc = window.hidden3.positions[node.id]
    window.visnetwork.moveNode(node.id,oldLoc.x,oldLoc.y)
  window.hidden3 = {nodes:[],edges:[], positions:{}}
  $(".context-hideSelections3").text("Hide3")
window.hidden3 = {nodes:[],edges:[], positions:{}}

spawnHidden3 = ()->
  hiddenNodes = (each.id for each in window.hidden3.nodes)
  hiddenEdges = (each.id for each in window.hidden3.edges)
  spawnTheseToQuikVis("contents of hidden buffer 3", hiddenNodes,hiddenEdges,window.hidden3.positions)

hideSelections4 = ()->
  elementIDs = window.visnetwork.getSelection()
  nodes2Hide = window.visnetwork.body.data.nodes.getDataSet().get(elementIDs.nodes)
  edges2Hide = window.visnetwork.body.data.edges.getDataSet().get(elementIDs.edges)
  window.hidden4 = if window.hidden4 then window.hidden4 else {nodes:[],edges:[], positions:{}}
  #pin nodes
  for node in nodes2Hide
    node.physics = false
  #unpin edges
  for edge in edges2Hide
    edge.physics = true
  window.hidden4.nodes = _.union window.hidden4.nodes, nodes2Hide
  window.hidden4.edges = _.union window.hidden4.edges, edges2Hide
  window.hidden4.positions = _.extend window.hidden4.positions, window.visnetwork.getPositions(elementIDs.nodes)
  window.visnetwork.body.data.edges.getDataSet().remove(elementIDs.edges)
  window.visnetwork.body.data.nodes.getDataSet().remove(elementIDs.nodes)
  window.visnetwork.setSelection({ nodes: [], edges: []})
  $(".context-hideSelections4").text(""+window.hidden4.nodes.length+"v,"+window.hidden4.edges.length+"e")

unhideSelections4 = ()->
  window.hidden4 = if window.hidden4 then window.hidden4 else {nodes:[],edges:[], positions:{}}
  window.visnetwork.body.data.nodes.getDataSet().add window.hidden4.nodes
  window.visnetwork.body.data.edges.getDataSet().add window.hidden4.edges
  window.visnetwork.setSelection({ nodes: (each.id for each in window.hidden4.nodes), edges: (each.id for each in window.hidden4.edges)})
  for node in window.hidden4.nodes
    oldLoc = window.hidden4.positions[node.id]
    window.visnetwork.moveNode(node.id,oldLoc.x,oldLoc.y)
  window.hidden4 = {nodes:[],edges:[], positions:{}}
  $(".context-hideSelections4").text("Hide4")
window.hidden4 = {nodes:[],edges:[], positions:{}}

spawnHidden4 = ()->
  hiddenNodes = (each.id for each in window.hidden4.nodes)
  hiddenEdges = (each.id for each in window.hidden4.edges)
  spawnTheseToQuikVis("contents of hidden buffer 4", hiddenNodes,hiddenEdges,window.hidden4.positions)


allHiddenNodeIDs = ()->
  (each.id for each in (window.hidden1.nodes.concat(window.hidden2.nodes,window.hidden3.nodes,window.hidden4.nodes)))

allHiddenEdgeIDs = ()->
  (each.id for each in (window.hidden1.edges.concat(window.hidden2.edges,window.hidden3.edges,window.hidden4.edges)))

dropSelections = ()->
  elementIDs = window.visnetwork.getSelection()
  nodes2Hide = window.visnetwork.body.data.nodes.getDataSet().get(elementIDs.nodes)
  edges2Hide = window.visnetwork.body.data.edges.getDataSet().get(elementIDs.edges)
  window.visnetwork.body.data.edges.getDataSet().remove(elementIDs.edges)
  window.visnetwork.body.data.nodes.getDataSet().remove(elementIDs.nodes)


growSelections = ()->
  if window.UsingGraphSON3
    growSelectionsGraphSON3()
  else
    growSelectionsGraphSON1()

growSelectionsGraphSON1 = ()->
#grow means add neighboring vertices and their edges from the database into the local render
  elementIDs = window.visnetwork.getSelection()
  if elementIDs.nodes.length > 0
    bindings = {vIDs: elementIDs.nodes}
    nl = "\n"
    script = "//answer all neighbors to these node IDs, vIDs is a binding" + nl +
      "inVs = vIDs.collect { g.V(it).in().toList() }" + nl +
      "inVs = inVs.flatten().unique()" + nl +
      "outVs = vIDs.collect { g.V(it).out().toList() }" + nl +
      "outVs = outVs.flatten().unique()" + nl +
      "inEs = vIDs.collect { g.V(it).inE().toList() }" + nl +
      "inEs = inEs.flatten().unique()" + nl +
      "outEs = vIDs.collect { g.V(it).outE().toList() }" + nl +
      "outEs = outEs.flatten().unique()" + nl +
      "[inVs,outVs,inEs,outEs]"
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
          else
            results = json.result.data
            nds = window.visnetwork.body.data.nodes.getDataSet()
            eds = window.visnetwork.body.data.edges.getDataSet()
            inVs = _.filter(results[0], (e)->
              nds.get(e.id) == null
            )
            outVs = _.filter(results[1], (e)->
              nds.get(e.id) == null
            )
            inEs = _.filter(results[2], (e)->
              eds.get(e.id) == null
            )
            outEs = _.filter(results[3], (e)->
              eds.get(e.id) == null
            )

            allV = _.uniq(_.union(inVs,outVs))
            ahn = allHiddenNodeIDs()
            allV = _.reject(allV, (node)->
              _.contains(ahn,node.id+""))
            allE = _.uniq(_.union(inEs,outEs))
            ahe = allHiddenEdgeIDs()
            allE = _.reject(allE, (edge)->
              _.contains(ahe,edge.id))
            nodes2Select = _.initial elementIDs.nodes, 0
            edges2Select = _.initial elementIDs.edges, 0
            if allV.length > 100
#too many to auto insert without user permissions and selection
              selectNeighborsToAdd(nodes2Select,edges2Select,allV,allE)
            else
              addInTheNeighbors(nodes2Select,edges2Select,allV,allE)
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Get neighbors', script, bindings, (error,result)->
        if result.success == true
          results = result.results
          console.log results
          nds = window.visnetwork.body.data.nodes.getDataSet()
          eds = window.visnetwork.body.data.edges.getDataSet()
          inVs = _.filter(results[0], (e)->
            nds.get(e.id) == null
          )
          outVs = _.filter(results[1], (e)->
            nds.get(e.id) == null
          )
          inEs = _.filter(results[2], (e)->
            eds.get(e.id) == null
          )
          outEs = _.filter(results[3], (e)->
            eds.get(e.id) == null
          )
          allV = _.uniq(_.union(inVs,outVs))
          ahn = allHiddenNodeIDs()
          allV = _.reject(allV, (node)->
            _.contains(ahn,node.id+""))
          allE = _.uniq(_.union(inEs,outEs))
          ahe = allHiddenEdgeIDs()
          allE = _.reject(allE, (edge)->
            _.contains(ahe,edge.id))
          nodes2Select = _.initial elementIDs.nodes, 0
          edges2Select = _.initial elementIDs.edges, 0
          if allV.length + allE.length > 20
#too many to auto insert without user permissions and selection
            selectNeighborsToAdd(nodes2Select,edges2Select,allV,allE)
          else
            addInTheNeighbors(nodes2Select,edges2Select,allV,allE)
        else
          alert "Graph update failed.  Nothing changed.  Maybe try again?"

growSelectionsGraphSON3 = ()->
#grow means add neighboring vertices and their edges from the database into the local render
  elementIDs = window.visnetwork.getSelection()
  if elementIDs.nodes.length > 0
    bindings = {vIDs: elementIDs.nodes}
    nl = "\n"
    script = "//answer all neighbors to these node IDs, vIDs is a binding" + nl +
      "inVs = vIDs.collect { g.V(it).in().toList() }" + nl +
      "inVs = inVs.flatten().unique()" + nl +
      "outVs = vIDs.collect { g.V(it).out().toList() }" + nl +
      "outVs = outVs.flatten().unique()" + nl +
      "inEs = vIDs.collect { g.V(it).inE().toList() }" + nl +
      "inEs = inEs.flatten().unique()" + nl +
      "outEs = vIDs.collect { g.V(it).outE().toList() }" + nl +
      "outEs = outEs.flatten().unique()" + nl +
      "[inVs,outVs,inEs,outEs]"
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
          else
            results = arrayFromGraphSON3List(json.result.data)
            nds = window.visnetwork.body.data.nodes.getDataSet()
            eds = window.visnetwork.body.data.edges.getDataSet()
            inVs = _.filter(arrayFromGraphSON3List(results[0]), (e)->
              eID = e['@value']['id']['@value']
              nds.get(eID) == null
            )
            outVs = _.filter(arrayFromGraphSON3List(results[1]), (e)->
              eID = e['@value']['id']['@value']
              nds.get(eID) == null
            )
            inEs = _.filter(arrayFromGraphSON3List(results[2]), (e)->
              eID = e['@value']['id']['@value']['relationId']
              eds.get(eID) == null
            )
            outEs = _.filter(arrayFromGraphSON3List(results[3]), (e)->
              eID = e['@value']['id']['@value']['relationId']
              eds.get(eID) == null
            )
            allV = _.uniq(_.union(inVs,outVs))
            ahn = allHiddenNodeIDs()
            allV = _.reject(allV, (node)->
              _.contains(ahn,node.id+""))
            allE = _.uniq(_.union(inEs,outEs))
            ahe = allHiddenEdgeIDs()
            allE = _.reject(allE, (edge)->
              _.contains(ahe,edge.id))
            nodes2Select = _.initial elementIDs.nodes, 0
            edges2Select = _.initial elementIDs.edges, 0
            if allV.length > 100
#too many to auto insert without user permissions and selection
              selectNeighborsToAdd(nodes2Select,edges2Select,allV,allE)
            else
              addInTheNeighbors(nodes2Select,edges2Select,allV,allE)
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Get neighbors', script, bindings, (error,result)->
        if result.success == true
          results = result.results
          console.log results
          nds = window.visnetwork.body.data.nodes.getDataSet()
          eds = window.visnetwork.body.data.edges.getDataSet()
          inVs = _.filter(results[0], (e)->
            nds.get(e.id) == null
          )
          outVs = _.filter(results[1], (e)->
            nds.get(e.id) == null
          )
          inEs = _.filter(results[2], (e)->
            eds.get(e.id) == null
          )
          outEs = _.filter(results[3], (e)->
            eds.get(e.id) == null
          )
          allV = _.uniq(_.union(inVs,outVs))
          ahn = allHiddenNodeIDs()
          allV = _.reject(allV, (node)->
            _.contains(ahn,node.id+""))
          allE = _.uniq(_.union(inEs,outEs))
          ahe = allHiddenEdgeIDs()
          allE = _.reject(allE, (edge)->
            _.contains(ahe,edge.id))
          nodes2Select = _.initial elementIDs.nodes, 0
          edges2Select = _.initial elementIDs.edges, 0
          if allV.length + allE.length > 20
#too many to auto insert without user permissions and selection
            selectNeighborsToAdd(nodes2Select,edges2Select,allV,allE)
          else
            addInTheNeighbors(nodes2Select,edges2Select,allV,allE)
        else
          alert "Graph update failed.  Nothing changed.  Maybe try again?"


expandSelections = ()->
#expanding means select nodes add edges to selection and selected edges add nodes
  elementIDs = window.visnetwork.getSelection()
  nodes2Select = _.initial elementIDs.nodes, 0
  edges2Select = _.initial elementIDs.edges, 0
  for nodeID in elementIDs.nodes
    newEdges = window.visnetwork.getConnectedEdges(nodeID)
    for newEdge in newEdges
      edges2Select.push newEdge
  for edgeID in elementIDs.edges
    newNodes = window.visnetwork.getConnectedNodes(edgeID)
    for newNode in newNodes
      nodes2Select.push newNode
  window.visnetwork.setSelection({nodes: _.uniq(nodes2Select), edges: _.uniq(edges2Select)})

expandSelections5 = ()->
  #expanding means select nodes add edges to selection and selected edges add nodes
  #take it out to 5 levels of neighbors
  expandSelections()
  expandSelections()
  expandSelections()
  expandSelections()
  expandSelections()

deleteSelections = ()->
  elementIDs = window.visnetwork.getSelection()
  bindings = {"vertIDs": elementIDs.nodes, "edgeIDs": elementIDs.edges}
  script = "//given arrays of vert ids and edge ids, remove their elements in the graph"+"\n"
  if elementIDs.nodes.length > 0
    script = script + "g.V(vertIDs).drop().iterate()"+"\n"
  if elementIDs.edges.length > 0
    script = script + "g.E(edgeIDs).drop().iterate()"+"\n"
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        window.visnetwork.body.data.edges.getDataSet().remove(elementIDs.edges)
        window.visnetwork.body.data.nodes.getDataSet().remove(elementIDs.nodes)
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('usingWebServices'),'Deleting a collection of verts and edges by id', script, bindings, (error,result)->
      if result.success == true
        window.visnetwork.body.data.edges.getDataSet().remove(elementIDs.edges)
        window.visnetwork.body.data.nodes.getDataSet().remove(elementIDs.nodes)
      else
        alert "Selection deletion failed.  Nothing changed; "+script

cloneSelections = ()->
  elementIDs = window.visnetwork.getSelection()
  cloneElements(elementIDs)

#-----------------for use from other functions-----------------

addElementsFromBindingsJSON = (bindings)->
  #Ignoring the case where GraphSON3 bindings are ingested into GraphSON1 graph.....this will BREAK
  script =
    '''
  if (bindings['vertsJSON'] == null) {vertsJSON = []} else {vertsJSON = bindings['vertsJSON']}
  if (bindings['edgesJSON'] == null) {edgesJSON = []} else {edgesJSON = bindings['edgesJSON']}
  if (bindings['verts2FindOrCreate'] == null) {verts2FindOrCreate = []} else {verts2FindOrCreate = bindings['verts2FindOrCreate']}
  if (bindings['transactionContext'] == null) {transactionContext = 'unlabeled transaction context'} else {transactionContext = bindings['transactionContext']}

  vMap = [:]
  vMapFull = [:]
  eMapFull = [:]
  verts2FindOrCreate.collect { json ->
      trav = g.V().hasLabel(json.label)
      json.properties.each { key, val ->
          trav = trav.has(key, val[0].value)
          }
      results = trav.toList()
     if (results.size == 0) {oldV = null} else {oldV = results[0]}
      if (oldV == null){
          //create it
          newV = g.addV(json.label).next()
          json.properties.each { key, val ->
              g.V(newV.id()).property(key, val[0].value).next()
              }
      } else {
          //reference it
          newV = oldV
      }
      vMap[json.id] = newV.id()

  }


  vertsJSON.collect { json ->
      newV = g.addV(json.label).next()
      vMap[json.id] = newV.id()
      vMapFull[json.id] = newV
      json.properties.each { key, val ->
          g.V(newV.id()).property(key, val[0].value).next()
  }}
  edgesJSON.collect { json ->
      fromID = vMap[json.outV] ? vMap[json.outV] : json.outV
      toID = vMap[json.inV] ? vMap[json.inV] : json.inV
      newEdge=g.V(fromID).addE(json.label).to(g.V(toID)).next()
      eMapFull[json.id] = newEdge
      json.properties.collect { key, val ->
          g.E(newEdge.id()).property(key, val.value).next()
  }}
  //answer the maps of old element ids to new elements
  [vMapFull, eMapFull]
  '''
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if json.status.code == 204
          results = []
        else
          results = json.result.data
          vMap = results[0]
          eMap = results[1]
          nodeIDsToSelect = []
          edgeIDsToSelect = []
          for oldVID,newV of vMap
            newNode = {physics: false, id: String(newV.id),label: labelForVertex(newV,Session.get('keyForNodeLabel')), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(newV), element:newV}
            window.visnetwork.nodesHandler.body.data.nodes.add newNode
            if bindings['locations'] && bindings.locations[oldVID]
              loc = bindings.locations[oldVID.toString()]
              window.visnetwork.moveNode(newNode.id,loc.x,loc.y)
            else
              window.visnetwork.moveNode(newNode.id,0,0)
            if bindings['styles'] && bindings.styles[oldVID.toString()]
              styleForNode = bindings.styles[oldVID.toString()]
              newNode = _.extend(newNode,styleForNode)
              window.visnetwork.nodesHandler.body.data.nodes.getDataSet().update(newNode)
              window.visnetwork.moveNode(newNode.id,loc.x,loc.y)
            nodeIDsToSelect.push newNode.id
          for oldEID,newE of eMap
            newEdge = {id: String(newE.id),label: newE.label, from: newE.outV, to: newE.inV, title: titleForElement(newE), element:newE}
            if bindings['styles'] && bindings.styles[oldEID.toString()]
              styleForEdge = bindings.styles[oldEID.toString()]
              newEdge = _.extend(newEdge,styleForEdge)
            window.visnetwork.edgesHandler.body.data.edges.add newEdge
            edgeIDsToSelect.push newEdge.id
          window.visnetwork.setSelection({nodes: nodeIDsToSelect, edges: edgeIDsToSelect},{unselectedAll: true, highlightEdges: false})
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: {bindings: bindings}, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Subgraph ingestor from bindings JSON', script, {bindings: bindings}, (error,result)->
      if result.success == true
        vMap = result.results[0]
        eMap = result.results[1]
        nodeIDsToSelect = []
        edgeIDsToSelect = []
        for oldVID,newV of vMap
          newNode = {id: String(newV.id),label: labelForVertex(newV,Session.get('keyForNodeLabel')), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(newV), element:newV}
          window.visnetwork.nodesHandler.body.data.nodes.add newNode
          oldLoc = (window.visnetwork.getPositions([oldVID]))[oldVID]
          window.visnetwork.moveNode(newNode.id,oldLoc.x + 50,oldLoc.y + 50)
          nodeIDsToSelect.push newNode.id
        for oldEID,newE of eMap
          newEdge = {id: String(newE.id),label: newE.label, from: newE.outV, to: newE.inV, title: titleForElement(newE), element:newE}
          window.visnetwork.edgesHandler.body.data.edges.add newEdge
          edgeIDsToSelect.push newEdge.id
        window.visnetwork.setSelection({nodes: nodeIDsToSelect, edges: edgeIDsToSelect},{unselectedAll: true, highlightEdges: false})
      else
        alert "Selection cloning failed.  Nothing changed; "+script

addElementsFromBindingsJSONGraphSON3 = (bindings)->
  #Need to handle the case where GraphSON1 bindings are ingested into GraphSON3 graph
  console.log bindings
  script =
    '''
  println '***************************************************************************************'
  println bindings
  println '***************************************************************************************'
  if (bindings['vertsJSON'] == null) {vertsJSON = []} else {vertsJSON = bindings['vertsJSON']}
  if (bindings['edgesJSON'] == null) {edgesJSON = []} else {edgesJSON = bindings['edgesJSON']}
  vMap = [:]
  vMapFull = [:]
  eMapFull = [:]

  vertsJSON.collect { json ->
      newV = g.addV(json.label).next()
      println '-------------'
      println json
      println "ingestId="+json.id.toString()
      println "newId="+newV.id().toString()
      println '-------------'
      vMap[json.id] = newV.id()
      vMapFull[json.id] = newV
    if(json['properties'] != null){
      json.properties.each { key, val ->
println "--------v---------->   "+val[0].toString()
println "--------v---------->   "+val[0].value().toString()
         g.V(newV.id()).property(key, val[0].value()).next()
}
  }}
  edgesJSON.collect { json ->
     println '-------------'
      println json
      println "ingestId="+json.id.toString()
      fromID = vMap[json.outV] ? vMap[json.outV] : json.outV
      toID = vMap[json.inV] ? vMap[json.inV] : json.inV
      newEdge=g.V(fromID).addE(json.label).to(g.V(toID)).next()
      eMapFull[json.id] = newEdge
       println "newEdgeId="+newEdge.id().toString()
      println '-------------'

    if (json['properties'] != null){
      json.properties.collect { key, val ->
println "--------e---------->   "+val.toString()
          g.E(newEdge.id()).property(key, val.value()).next()
}
  }}
  //answer the maps of old element ids to new elements
  [vMapFull, eMapFull]
  '''
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if json.status.code == 204
          results = []
        else
          results = json.result.data
          vMap = objectFromGraphSON3Map(results['@value'][0])
          eMap = objectFromGraphSON3Map(results['@value'][1])
          nodeIDsToSelect = []
          edgeIDsToSelect = []
          for oldVID,newV of vMap
            newV.type = 'vertex'
            newNode = {physics: false, id: String(newV.id['@value']),label: labelForVertexGraphSON3(newV,Session.get('keyForNodeLabel')), allowedToMoveX: true, allowedToMoveY: true, title: titleForElementGraphSON3(newV), element:newV}
            window.visnetwork.nodesHandler.body.data.nodes.add newNode
            if bindings['locations'] && bindings.locations[oldVID]
              loc = bindings.locations[oldVID.toString()]
              window.visnetwork.moveNode(newNode.id,loc.x,loc.y)
            else
              window.visnetwork.moveNode(newNode.id,0,0)
            if bindings['styles'] && bindings.styles[oldVID.toString()]
              styleForNode = bindings.styles[oldVID.toString()]
              newNode = _.extend(newNode,styleForNode)
              window.visnetwork.nodesHandler.body.data.nodes.getDataSet().update(newNode)
              window.visnetwork.moveNode(newNode.id,loc.x,loc.y)
            nodeIDsToSelect.push newNode.id
          for oldEID,newE of eMap
            newE.type = 'edge'
            newEdge = {id: String(newE.id['@value']['relationId']),label: newE.label, from: newE.outV['@value'], to: newE.inV['@value'], title: titleForElementGraphSON3(newE), element:newE}
            if bindings['styles'] && bindings.styles[oldEID.toString()]
              styleForEdge = bindings.styles[oldEID.toString()]
              newEdge = _.extend(newEdge,styleForEdge)
            window.visnetwork.edgesHandler.body.data.edges.add newEdge
            edgeIDsToSelect.push newEdge.id
          window.visnetwork.setSelection({nodes: nodeIDsToSelect, edges: edgeIDsToSelect},{unselectedAll: true, highlightEdges: false})
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: {bindings: bindings}, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Subgraph ingestor from bindings JSON', script, {bindings: bindings}, (error,result)->
      if result.success == true
        vMap = result.results[0]
        eMap = result.results[1]
        nodeIDsToSelect = []
        edgeIDsToSelect = []
        for oldVID,newV of vMap
          newNode = {id: String(newV.id),label: labelForVertex(newV,Session.get('keyForNodeLabel')), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(newV), element:newV}
          window.visnetwork.nodesHandler.body.data.nodes.add newNode
          oldLoc = (window.visnetwork.getPositions([oldVID]))[oldVID]
          window.visnetwork.moveNode(newNode.id,oldLoc.x + 50,oldLoc.y + 50)
          nodeIDsToSelect.push newNode.id
        for oldEID,newE of eMap
          newEdge = {id: String(newE.id),label: newE.label, from: newE.outV, to: newE.inV, title: titleForElement(newE), element:newE}
          window.visnetwork.edgesHandler.body.data.edges.add newEdge
          edgeIDsToSelect.push newEdge.id
        window.visnetwork.setSelection({nodes: nodeIDsToSelect, edges: edgeIDsToSelect},{unselectedAll: true, highlightEdges: false})
      else
        alert "Selection cloning failed.  Nothing changed; "+script






cloneElements = (elementIDs)->
  bindings = {"vertIDs": elementIDs.nodes, "edgeIDs": elementIDs.edges}
  script = "//given arrays of vert ids and edge ids, clone the subgraph defined into the graph"+"\n"
  # use bindings instead of codegen to reuse last compiled version of script
  #  script = script + "vertIDs = "+JSON.stringify(elementIDs.nodes)+"\n"
  #  script = script + "edgeIDs = "+JSON.stringify(elementIDs.edges)+"\n"
  script = script + "//clone vertices first"+"\n"
  script = script + "vMap = [:]"+"\n"
  script = script + "vMapFull = [:]"+"\n"
  script = script + "vertIDs.each { id ->"+"\n"
  script = script + "   oldVert = g.V(id).next()"+"\n"
  script = script + "   newVert = g.addV(oldVert.label()).next()"+"\n"
  script = script + "   vMap[oldVert.id()] = newVert.id()"+"\n"
  script = script + "   vMapFull[oldVert.id()] = newVert"+"\n"
  script = script + "   oldVert.properties().toList().collect {prop ->"+"\n"
  script = script + "       g.V(newVert.id()).property(prop.label(), prop.value()).next()"+"\n"
  script = script + "}}"+"\n"
  script = script + "//clone edges"+"\n"
  script = script + "eMapFull = [:]"+"\n"
  script = script + "edgeIDs.each { id ->"+"\n"
  script = script + "   oldEdge = g.E(id).next()"+"\n"
  script = script + "   fromID = vMap[oldEdge.outVertex().id()] ? vMap[oldEdge.outVertex().id()] : oldEdge.outVertex().id()"+"\n"
  script = script + "   toID = vMap[oldEdge.inVertex().id()] ? vMap[oldEdge.inVertex().id()] : oldEdge.inVertex().id()"+"\n"
  script = script + "   newEdge=g.V(fromID).addE(oldEdge.label()).to(g.V(toID)).next()"+"\n"
  script = script + "   eMapFull[oldEdge.id()] = newEdge"+"\n"
  script = script + "   oldEdge.properties().toList().collect { prop ->"+"\n"
  script = script + "       g.E(newEdge.id()).property(prop.key(), prop.value()).next()"+"\n"
  script = script + "}}"+"\n"
  script = script + "//answer the maps"+"\n"
  script = script + "[vMapFull,eMapFull]"+"\n"
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        if json.status.code == 204
          results = []
        else
          results = json.result.data
          nodeIDsToSelect = []
          edgeIDsToSelect = []
          if window.UsingGraphSON3
            vMap = objectFromGraphSON3Map(results['@value'][0])
            eMap = objectFromGraphSON3Map(results['@value'][1])
            for oldVID,newV of vMap
              newV.type = 'vertex'
              newNode = {id: String(newV.id['@value']),label: labelForVertexGraphSON3(newV,Session.get('keyForNodeLabel')), allowedToMoveX: true, allowedToMoveY: true, title: titleForElementGraphSON3(newV), element:newV}
              window.visnetwork.nodesHandler.body.data.nodes.add newNode
              oldLoc = (window.visnetwork.getPositions([oldVID]))[oldVID]
              window.visnetwork.moveNode(newNode.id,oldLoc.x + 50,oldLoc.y + 50)
              nodeIDsToSelect.push newNode.id
            for oldEID,newE of eMap
              newE.type = 'edge'
              newEdge = {id: String(newE.id['@value']['relationId']),label: newE.label, from: newE.outV['@value'], to: newE.inV['@value'], title: titleForElementGraphSON3(newE), element:newE}
              window.visnetwork.edgesHandler.body.data.edges.add newEdge
              edgeIDsToSelect.push newEdge.id
          else
            vMap = results[0]
            eMap = results[1]
            for oldVID,newV of vMap
              newNode = {id: String(newV.id),label: labelForVertex(newV,Session.get('keyForNodeLabel')), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(newV), element:newV}
              window.visnetwork.nodesHandler.body.data.nodes.add newNode
              oldLoc = (window.visnetwork.getPositions([oldVID]))[oldVID]
              window.visnetwork.moveNode(newNode.id,oldLoc.x + 50,oldLoc.y + 50)
              nodeIDsToSelect.push newNode.id
            for oldEID,newE of eMap
              newEdge = {id: String(newE.id),label: newE.label, from: newE.outV, to: newE.inV, title: titleForElement(newE), element:newE}
              window.visnetwork.edgesHandler.body.data.edges.add newEdge
              edgeIDsToSelect.push newEdge.id
          window.visnetwork.setSelection({nodes: nodeIDsToSelect, edges: edgeIDsToSelect},{unselectedAll: true, highlightEdges: false})
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: bindings, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Subgraph cloner', script, bindings, (error,result)->
      if result.success == true
        vMap = result.results[0]
        eMap = result.results[1]
        nodeIDsToSelect = []
        edgeIDsToSelect = []
        for oldVID,newV of vMap
          newNode = {id: String(newV.id),label: labelForVertex(newV,Session.get('keyForNodeLabel')), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(newV), element:newV}
          window.visnetwork.nodesHandler.body.data.nodes.add newNode
          oldLoc = (window.visnetwork.getPositions([oldVID]))[oldVID]
          window.visnetwork.moveNode(newNode.id,oldLoc.x + 50,oldLoc.y + 50)
          nodeIDsToSelect.push newNode.id
        for oldEID,newE of eMap
          newEdge = {id: String(newE.id),label: newE.label, from: newE.outV, to: newE.inV, title: titleForElement(newE), element:newE}
          window.visnetwork.edgesHandler.body.data.edges.add newEdge
          edgeIDsToSelect.push newEdge.id
        window.visnetwork.setSelection({nodes: nodeIDsToSelect, edges: edgeIDsToSelect},{unselectedAll: true, highlightEdges: false})
      else
        alert "Selection cloning failed.  Nothing changed; "+script


addEdgeToGraph = (edgeData, callback) ->
#edgeData is the vis.js object for its newly created edge on the client, {from: "id of node", to: "id of node"}
  labels = Session.get 'edgeLabelSet'
  labelSelectorHTML = '<select onchange="window.updateVertexLabelBootBox(this)" >'
  optionHTML = '<option>Select an edge label</option>'
  labelSelectorHTML = labelSelectorHTML + optionHTML
  for label in labels
    do(label)->
      optionHTML = '<option>'+label+'</option>'
      labelSelectorHTML = labelSelectorHTML + optionHTML
  labelSelectorHTML = labelSelectorHTML + '</select>'
  bootbox.prompt("<p>Enter the label for this new edge or choose one of these "+labelSelectorHTML+"</p><p>Edge labels are immutable (can't be changed), so choose wisely.</p>", (result)->
    label = result
    if label == null || label == ""
    #alert "Edges must have labels, adding edge aborted"
      callback(null)
      return
    script = 'fromV = g.V("'+edgeData.from+'");'
    script = script + 'toV = g.V("'+edgeData.to+'");'
    script = script + 'e = fromV.addE("'+label+'").to(toV)'
    if (Session.get "usingWebSockets")
      window.socketToJanus.onmessage = (msg) ->
        endTime = Date.now()
        data = msg.data
        json = JSON.parse(data)
        if json.status.code >= 500
          alert "Error in processing Gremlin script: "+json.status.message
        else
          if json.status.code == 204
            results = []
            edgeData = []
          else
            if window.UsingGraphSON3
              results = json.result.data['@value']
              e = results[0]['@value']
              e.type = 'edge'
              edgeData.id = String(e.id['@value']['relationId'])
              edgeData.from = String(e.outV['@value'])
              edgeData.to = String(e.inV['@value'])
              edgeData.label = e.label
              edgeData.title = titleForElementGraphSON3(e)
            else
              results = json.result.data
              e = results[0]
              edgeData.id = String(e.id)
              edgeData.from = String(e.outV)
              edgeData.to = String(e.inV)
              edgeData.label = e.label
              edgeData.title = titleForElement(e)
            edgeData.element = e
           # console.log edgeData
          getLabelSets()
          callback(edgeData)
      request =
        requestId: uuid.new(),
        op:"eval",
        processor:"",
        args:{gremlin: script, bindings: {}, language: "gremlin-groovy"}
      startTime = Date.now()
      window.socketToJanus.send(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in property updater', script, (error,result)->
        if result.success == true
          e = result.results[0]
          edgeData.id = String(e.id)
          edgeData.from = String(e.outV)
          edgeData.to = String(e.inV)
          edgeData.label = e.label
          edgeData.title = titleForElement(e)
          edgeData.element = e
          getLabelSets()
          callback(edgeData)
        else
          alert "Graph update failed.  Nothing changed"
  )
  #update vertex label set in case new ones have been added
  getLabelSets()

deleteSelected = (selections,callback)->
  #selections is { nodes:[], edges:[] }
  nodeIDs = selections.nodes
  edgeIDs = selections.edges
  script = 'nodeIDs.each {nodeID -> g.V(nodeID).drop()}; edgeIDs.each {edgeID -> g.V(edgeID).drop()}; '
  bindings = {nodeIDs: nodeIDs, edgeIDs:edgeIDs}
  if (Session.get "usingWebSockets")
    window.socketToJanus.onmessage = (msg) ->
      endTime = Date.now()
      data = msg.data
      json = JSON.parse(data)
      if json.status.code >= 500
        alert "Error in processing Gremlin script: "+json.status.message
      else
        callback(selections)
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: script, bindings: {nodeIDs: nodeIDs, edgeIDs: edgeIDs}, language: "gremlin-groovy"}
    startTime = Date.now()
    window.socketToJanus.send(JSON.stringify(request))
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'Built-in property updater', script, bindings, (error,result)->
      if result.success == true
        callback(selections)
      else
        alert "Graph update failed.  Nothing changed"

userPropertiesForElement = (element)->
#this does not try to handle multivalue properties yet, only returns the first one
  props = {}
  if element["properties"] != undefined
    for key in _.keys element.properties
      if element.type == "vertex"
        props[key] = element.properties[key][0].value
      else   #edge properties aren't multivalued
        props[key] = element.properties[key]
  return props

labelForVertex = (vertex, keyForLabel)->
  if keyForLabel == undefined
    key = "null"
  else
    key = keyForLabel
  if Session.get 'useLabelPrefix'
    labelPrefix = vertex.label
  else
    labelPrefix = ""
  suffix = ""
  if (vertex[key] == undefined)
    if vertex.properties[key] != undefined
      suffix = key+": "+vertex.properties[key][0].value
    else
      suffix = ""
      nl = ""
  else
    suffix = key+": "+vertex[key]
  if suffix != ""
    nl = '\n'
  else
    nl = ""

  return labelPrefix+nl+suffix

userPropertiesForElementGraphSON3 = (element)->
#this does not try to handle multivalue properties yet, only returns the first one
  props = {}
  if element["properties"] != undefined
    for key in _.keys element.properties
      if element.type == undefined then debugger
      if element.type == "vertex"
        val = element.properties[key][0]['@value']['value']
        if val['@value'] then val = val['@value']
        if (typeof val == 'object') then val = geoshapeGraphSON3ToJava(val)
        props[key] = val
      else   #edge properties aren't multivalued
        val = element.properties[key]['@value']['value']
        if val['@value'] then val = val['@value']
        if (typeof val == 'object') then val = geoshapeGraphSON3ToJava(val)
        props[key] = val
  return props

labelForVertexGraphSON3 = (vertex, keyForLabel)->
  if keyForLabel == undefined
    key = "null"
  else
    key = keyForLabel
  if Session.get 'useLabelPrefix'
    labelPrefix = vertex.label
  else
    labelPrefix = ""
  suffix = ""
  if (vertex[key] == undefined)
    if vertex['properties'] && (vertex.properties[key] != undefined)
      suffix = key+": "+vertex.properties[key][0]['@value']
    else
      suffix = ""
      nl = ""
  else
    suffix = key+": "+vertex[key]
  if suffix != ""
    nl = '\n'
  else
    nl = ""
  return labelPrefix+nl+suffix

allKeysInVerts = (verts)->
#answer the collection of all unique vertex keys in verts
#include id, label, and properties, omit type (edge/vertex)
  allKeys = ['id','label']
  for v in verts
    allKeys.push(k) for k in Object.keys(v.properties)
  return _.uniq(allKeys)

window.updateEdgeColors = ()->
  conf = window.visnetwork.configurator.moduleOptions
  for edge in _.values window.visnetwork.edgesHandler.body.data.edges._data
    console.log edge
    if edge.color == undefined
      edge.color = {}
    edge.color = conf.edges.color.color
    edge.color.highlight = conf.edges.color.highlight
    edge.color.hover = conf.edges.color.hover
    edge.color.opacity = conf.edges.color.opacity
    edge.color.inherit = conf.edges.color.inherit
    window.visnetwork.edgesHandler.body.data.edges.update [edge], []

window.getElementTypeFromID = (id)->
  node = window.visnetwork.nodesHandler.body.data.nodes._data[id]
  edge = window.visnetwork.edgesHandler.body.data.edges._data[id]
  if node then return "vertex"
  if edge then return "edge"
  return null


window.renderGraph =  () ->
  Session.set 'graphRenderingStatus','Rendering...'
#  graph = Session.get 'graphToShow'
  Session.set 'renderStartTime', moment().toDate()
#vn = new vis.DataSet(graph.nodes)
#ve = new vis.DataSet(graph.edges)
#window.visnetwork.setData {nodes: vn, edges: ve}


window.setUpVis = () ->
  this.find('.results-vis')._uihooks
  container = document.getElementById 'mynetwork'
  config = document.getElementById 'vis-config'
  $(config).hide()
  visOptions = Session.get 'visOptions'
  defaultOptions =
    interaction:
      hover: true
      navigationButtons: true
      multiselect: true
      dragView: true
      selectConnectedEdges: false
    manipulation:
      addNode: (nodeData,callback)->
        addVertToGraph(nodeData,callback)
      addEdge: (edgeData,callback)->
        addEdgeToGraph(edgeData,callback)
      deleteNode: (selections, callback)->
        deleteSelected(selections,callback)
      deleteEdge: (selections, callback)->
        deleteSelected(selections,callback)
      editNode: (node,callback)->
        window.popupPropertyEditor(window.visnetwork.nodesHandler.body.data.nodes.get(node.id), "vertex")
        callback()
      editEdge: false
    configure:
      enabled: true
      container: config
      showButton: true
    physics: true
    nodes:
      shape: "box"
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

  window.visnetwork.on('afterDrawing', (params)->
    if (Session.get "firstRender") == 1
      renderStopTime = moment()
      d = moment.duration(Math.round((renderStopTime-moment(Session.get 'renderStartTime'))*1000)/1000)
      Session.set 'elapsedRenderTime', durationToString(d)
      graph = Session.get 'graphToShow'
      if graph.nodes.length > 0
        Session.set 'graphRenderingStatus', 'Finished '+graph.nodes.length+'V, '+graph.edges.length+'E'
    Session.set "firstRender", (Session.get "firstRender")+1
  )

  window.visnetwork.on('doubleClick', (params)->   # open a dialog for the selected element
    if params.nodes.length != 0 # then a node was doubleClicked
      elementType = 'vertex'
      element = window.visnetwork.nodesHandler.body.data.nodes.get(params.nodes[0])
    else
      if params.edges.length == 1 # then an edge was doubleClicked
        elementType = 'edge'
        element =  window.visnetwork.edgesHandler.body.data.edges.get(params.edges[0])
      else
        return #background was doubleClicked, nothing to do yet
    window.popupPropertyEditor(element, elementType)
  )
  $('.context-cloneSelections').click ->
    params = window.visnetwork.getSelection()
    cloneSelections(params.nodes, params.edges)

  $('.context-deleteSelections').click ->
    params = window.visnetwork.getSelection()
    bootbox.confirm
      message: "Do you really want to delete "+params.nodes.length+" vertices and "+params.edges.length+" edges?  (no undo)",
      buttons: {
        confirm: {
          label: 'Yes, delete them',
          className: 'btn-success'
        },
        cancel: {
          label: "No, don't delete anything",
          className: 'btn-danger'
        }
      },
      callback: (result) ->
        if result
          deleteSelections(params.nodes, params.edges)

  $('.context-expandSelections').click ->
    expandSelections()

  $('.context-expandSelections5').click ->
    expandSelections5()

  $('.context-dropSelections').click ->
    dropSelections()

  $('.context-growSelections').click ->
    growSelections()

  $('.context-selectAll').click ->
    selectAll()

  $('.context-selectNone').click ->
    selectNone()

  $('.context-invertSelections').click ->
    invertSelections()

  $('.context-hideSelections1').click ->
    hideSelections1()
  $('.context-unhideSelections1').click ->
    unhideSelections1()
  $('.context-spawnHidden1').click ->
    spawnHidden1()


  $('.context-hideSelections2').click ->
    hideSelections2()
  $('.context-unhideSelections2').click ->
    unhideSelections2()
  $('.context-spawnHidden2').click ->
    spawnHidden2()

  $('.context-hideSelections3').click ->
    hideSelections3()
  $('.context-unhideSelections3').click ->
    unhideSelections3()
  $('.context-spawnHidden3').click ->
    spawnHidden3()

  $('.context-hideSelections4').click ->
    hideSelections4()
  $('.context-unhideSelections4').click ->
    unhideSelections4()
  $('.context-spawnHidden4').click ->
    spawnHidden4()

  $('.context-inspectSelections').click ->
    inspectSelections()

  $('.context-inspectNone').click ->
    inspectNone()

  $('.context-pinSelections').click ->
    pinSelections()

  $('.context-unpinSelections').click ->
    unpinSelections()

  $('.context-generateJSONBindingsForSelections').click ->
    generateJSONBindingsForSelections()

  $('.context-shareGremlinCodeForIngestion').click ->
    shareGremlinCodeForIngestion()

  $('.context-inputGremlinCodeForIngestion').click ->
    inputGremlinCodeForIngestion()

  $('.context-spawnToQuikVis').click ->
    spawnToQuikVis()

  $('.context-spawnAllToQuikVis').click ->
    spawnAllToQuikVis()

  window.popupPropertyEditor = (element, elementType)->
    id = element.element.id
    if id['@value']
      html = popupDialogForElementGraphSON3(element, elementType)
      if elementType == 'vertex'
        id = id['@value']
      else
        id = id['@value']['relationId']
    else
      html = popupDialogForElement(element, elementType)
    title = elementType + ': ' + id
    div = document.createElement 'div'
    div.class = 'doubleClick-dialog'
    div.innerHTML = html
    $(".vis-network").append div
    $(div).dialog(
      title: title
      resizable: true
      width: 500
      height: "auto"
      beforeClose: ( event, ui )->
        $(".propTableForElementID"+id).remove()
    )
    $('.element-deleteProperty'+id).click ->
      $(this.parentNode.parentNode.parentNode.parentNode.parentNode).next().show()
      this.parentNode.parentNode.parentNode.remove()

    $('.element-copyProperty'+id).click ->
      key = this.parentNode.parentNode.parentNode.children[0].innerText.slice(0,-1)
      value = this.parentNode.parentNode.parentNode.children[1].children[0].value
      if window.UsingGraphSON3
        type = this.parentNode.parentNode.parentNode.children[2].children[0].value
        Session.set "propCopyBuffer",{key: key,value: value, type: type}
        console.log "copied ",key,value,type
      else
        Session.set "propCopyBuffer",{key: key,value: value}
        console.log "copied ",key,value

    $('.element-pasteProperty'+id).click ->
      prop = Session.get "propCopyBuffer"
      elementType = window.getElementTypeFromID(id)
      if prop
        key = prop.key
        value = prop.value
        if window.UsingGraphSON3
          type = prop.type
        $(".propTableForElementID"+id).next().show()
        deletePropButton = '<a href="#" class="btn btn-default" title="Delete property"><span class="glyphicon glyphicon-minus element-deleteProperty'+id+'"></span></a>'
        copyPropButton = '<a href="#" class="btn btn-default" title="Copy property"><span class="glyphicon glyphicon-copy element-copyProperty'+id+'"></span></a>'
        if window.UsingGraphSON3
          cacheOriginalPropertyTypeGraphSON3(elementType,id,key,type)
          typeSelector = buildTypeSelectorHTMLGraphSON3(id,key,type,elementType,'disabled')
          tr = '<tr><td>'+key+':  </td><td style="width:100%"><input style="width:100%" type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'.commitButtonForElementID'+id+'\').show()"></td><td style="width:100%" id="'+id+'" value="'+elementType+'" name="'+key+'">'+typeSelector+deletePropButton+copyPropButton+'</td></tr>'
        else
          tr = '<tr><td>'+key+':  </td><td><input type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'button.commitButtonForElementID'+id+'\').show()"></td><th style="width:50" id="'+id+'" value="'+elementType+'" name="'+key+'">'+deletePropButton+copyPropButton+'</th></tr>'
        $(".propTableForElementID"+id).append(tr)
        $('.element-deleteProperty'+id).click ->
          $(".propTableForElementID"+id).next().show()
          this.parentNode.parentNode.parentNode.remove()
      else
        alert "Nothing to paste, try copying a property first"

    $('.element-log'+id).click ->
      node = window.visnetwork.nodesHandler.body.data.nodes.get(id)
      if node
        console.log node
      else
        edge = window.visnetwork.edgesHandler.body.data.edges.get(id)
        console.log edge

    $('.clone-vertex'+id).click ->
      cloneVertToGraph(id)

    $('.clone-edge'+id).click ->
      cloneElements({"nodes":[], "edges":[id]})

    $('.element-addProperty'+id).click ->
      bootbox.dialog(
        title: "Enter a name for the new property"
        message: '<div class="row">  ' +
          '<div class="col-md-12"> ' +
          '<form class="form-horizontal"> ' +
          '<div class="form-group"> ' +
          '<label class="col-md-4 control-label" for="name">Key</label> ' +
          '<div class="col-md-4"> ' +
          '<input id="key'+id+'" name="key" type="text" placeholder="aPropertyName" class="form-control input-md"> ' +
          '</div> ' +
          '<label class="col-md-4 control-label" for="name">Value</label> ' +
          '<div class="col-md-4"> ' +
          '<input id="value'+id+'" name="value" type="text" placeholder="someValue" class="form-control input-md"> ' +
          '</div> ' +
          '</form> </div>  </div>',
        buttons:
          confirm:
            label: "Save"
            className: "btn-success"
            callback: ()->
              key = $('#key'+id+'').val()
              value = $('#value'+id+'').val()
              if key == "id" | key == "label"| key == "type"
                window.alert('Reserved property name disallowed: '+key)
              else
                $(".propTableForElementID"+id).next().show()
                deletePropButton = '<a href="#" class="btn btn-default" title="Delete property"><span class="glyphicon glyphicon-minus element-deleteProperty'+id+'"></span></a>'
                copyPropButton = '<a href="#" class="btn btn-default" title="Copy property"><span class="glyphicon glyphicon-copy element-copyProperty'+id+'"></span></a>'
                tr = '<tr><td>'+key+':  </td><td><input type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'button.commitButtonForElementID'+id+'\').show()"></td><th style="width:50" id="'+id+'" value="'+elementType+'" name="'+key+'">'+deletePropButton+copyPropButton+'</th></tr>'
                $(".propTableForElementID"+id).append(tr)
                $('.element-deleteProperty'+id).click ->
                  $(".propTableForElementID"+id).next().show()
                  this.parentNode.parentNode.parentNode.remove()

      )

    $('.element-addVertexPropertyGraphSON3'+id).click ->
      bootbox.dialog(
        title: "Enter a name for the new property"
        message: '<div class="row">  ' +
          '<div class="col-md-12"> ' +
          '<form class="form-horizontal"> ' +
          '<div class="form-group"> ' +
          '<label class="col-md-4 control-label" for="name">Key</label> ' +
          '<div class="col-md-4"> ' +
          '<input id="key'+id+'" name="key" type="text" placeholder="aPropertyName" class="form-control input-md"> ' +
          '</div> ' +
          '<label class="col-md-4 control-label" for="name">Value</label> ' +
          '<div class="col-md-4"> ' +
          '<input id="value'+id+'" name="value" type="text" placeholder="someValue" class="form-control input-md"> ' +
          '</div> ' +
          '</form> </div>  </div>',
        buttons:
          confirm:
            label: "Save"
            className: "btn-success"
            callback: ()->
              key = $('#key'+id+'').val()
              value = $('#value'+id+'').val()
              if key == "id" | key == "label"| key == "type"
                window.alert('Reserved property name disallowed: '+key)
              else
                $(".propTableForElementID"+id).next().show()
                deletePropButton = '<a href="#" class="btn btn-default" title="Delete property"><span class="glyphicon glyphicon-minus element-deleteProperty'+id+'"></span></a>'
                copyPropButton = '<a href="#" class="btn btn-default" title="Copy property"><span class="glyphicon glyphicon-copy element-copyProperty'+id+'"></span></a>'
                cacheOriginalPropertyTypeGraphSON3('vertex',id,key,'String')
                typeSelector = buildTypeSelectorHTMLGraphSON3(id,key,'String','vertex','')
                tr = '<tr><td>'+key+':  </td><td style="width:100%"><input style="width:100%" type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'.commitButtonForElementID'+id+'\').show()"></td><td style="width:100%" id="'+id+'" value="'+elementType+'" name="'+key+'">'+typeSelector+deletePropButton+copyPropButton+'</td></tr>'
                #                tr = '<tr><td>'+key+':  </td><td><input type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'button.commitButtonForElementID'+id+'\').show()"></td><th style="width:50" id="'+id+'" value="'+elementType+'" name="'+key+'">'+deletePropButton+copyPropButton+'</th></tr>'
                $(".propTableForElementID"+id).append(tr)
                $('.element-deleteProperty'+id).click ->
                  $(".propTableForElementID"+id).next().show()
                  this.parentNode.parentNode.parentNode.remove()

      )
    $('.element-addEdgePropertyGraphSON3'+id).click ->
      bootbox.dialog(
        title: "Enter a name for the new property"
        message: '<div class="row">  ' +
          '<div class="col-md-12"> ' +
          '<form class="form-horizontal"> ' +
          '<div class="form-group"> ' +
          '<label class="col-md-4 control-label" for="name">Key</label> ' +
          '<div class="col-md-4"> ' +
          '<input id="key'+id+'" name="key" type="text" placeholder="aPropertyName" class="form-control input-md"> ' +
          '</div> ' +
          '<label class="col-md-4 control-label" for="name">Value</label> ' +
          '<div class="col-md-4"> ' +
          '<input id="value'+id+'" name="value" type="text" placeholder="someValue" class="form-control input-md"> ' +
          '</div> ' +
          '</form> </div>  </div>',
        buttons:
          confirm:
            label: "Save"
            className: "btn-success"
            callback: ()->
              key = $('#key'+id+'').val()
              value = $('#value'+id+'').val()
              if key == "id" | key == "label"| key == "type"
                window.alert('Reserved property name disallowed: '+key)
              else
                $(".propTableForElementID"+id).next().show()
                deletePropButton = '<a href="#" class="btn btn-default" title="Delete property"><span class="glyphicon glyphicon-minus element-deleteProperty'+id+'"></span></a>'
                copyPropButton = '<a href="#" class="btn btn-default" title="Copy property"><span class="glyphicon glyphicon-copy element-copyProperty'+id+'"></span></a>'
                cacheOriginalPropertyTypeGraphSON3('edge',id,key,'String')
                typeSelector = buildTypeSelectorHTMLGraphSON3(id,key,'String','edge','')
                tr = '<tr><td>'+key+':  </td><td style="width:100%"><input style="width:100%" type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'.commitButtonForElementID'+id+'\').show()"></td><td style="width:100%" id="'+id+'" value="'+elementType+'" name="'+key+'">'+typeSelector+deletePropButton+copyPropButton+'</td></tr>'
                #                tr = '<tr><td>'+key+':  </td><td><input type="text" class="propForElementID'+id+'" name='+key+' value="'+value+'" oninput="$(\'button.commitButtonForElementID'+id+'\').show()"></td><th style="width:50" id="'+id+'" value="'+elementType+'" name="'+key+'">'+deletePropButton+copyPropButton+'</th></tr>'
                $(".propTableForElementID"+id).append(tr)
                $('.element-deleteProperty'+id).click ->
                  $(".propTableForElementID"+id).next().show()
                  this.parentNode.parentNode.parentNode.remove()

      )

  $(".results-graph-fit").click ->
    window.visnetwork.fit()

  #------------------drag multiselect functions----------------------------
  rect = {}
  drag = false
  canvas = window.visnetwork.canvas.frame.canvas
  ctx = canvas.getContext('2d')
  drawingSurfaceImageData = ctx.getImageData(0, 0, canvas.width, canvas.height)


  saveDrawingSurface = ->
    drawingSurfaceImageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
    return

  restoreDrawingSurface = ->
    ctx.putImageData drawingSurfaceImageData, 0, 0
    return

  selectNodesFromHighlight = ->
    nodesIdInDrawing = Session.get('selectedNodes')
    xRange = getStartToEnd(rect.startX, rect.w)
    yRange = getStartToEnd(rect.startY, rect.h)
    allNodes = window.visnetwork.nodesHandler.body.data.nodes.get()
    i = 0
    while i < allNodes.length
      curNode = allNodes[i]
      nodePosition = window.visnetwork.getPositions([ curNode.id ])
      nodeXY = window.visnetwork.canvasToDOM(
        x: nodePosition[curNode.id].x
        y: nodePosition[curNode.id].y)
      if xRange.start <= nodeXY.x and nodeXY.x <= xRange.end and yRange.start <= nodeXY.y and nodeXY.y <= yRange.end
        nodesIdInDrawing.push curNode.id
      i++

    window.visnetwork.selectNodes nodesIdInDrawing
    return

  getStartToEnd = (start, theLen) ->
    if theLen > 0
      ret =
        start: start
        end: start + theLen
    else
      ret =
        start: start + theLen
        end: start
    return ret

  container = $("#mynetwork")
  container.on 'mousemove', (e) ->
    if drag
      restoreDrawingSurface()
      rect.w = e.pageX - (@offsetLeft) - (rect.startX)
      rect.h = e.pageY - (@offsetTop) - (rect.startY)
      ctx.setLineDash [ 5 ]
      ctx.strokeStyle = 'rgb(0, 102, 0)'
      ctx.strokeRect rect.startX, rect.startY, rect.w, rect.h
      ctx.setLineDash []
      ctx.fillStyle = 'rgba(0, 255, 0, 0.2)'
      ctx.fillRect rect.startX, rect.startY, rect.w, rect.h
    return

  container.on 'mousedown', (e) ->
    Session.set('selectedNodes', [])
    if e.button == 2
      if e.shiftKey
        currentSelections = window.visnetwork.getSelectedNodes()
        Session.set('selectedNodes', currentSelections)
      saveDrawingSurface()
      that = this
      rect.startX = e.pageX - (@offsetLeft)
      rect.startY = e.pageY - (@offsetTop)
      drag = true
      container[0].style.cursor = 'crosshair'
    return
  container.on 'mouseup', (e) ->
    if e.button == 2
      restoreDrawingSurface()
      drag = false
      container[0].style.cursor = 'default'
      selectNodesFromHighlight()
    return
  document.body.oncontextmenu = ->
    false




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
    updateNodelabels()

  updateNodelabels = () ->
    key = $("#nodeLabelProperty").val()
    Session.set 'keyForNodeLabel', key
    nodes = window.visnetwork.nodesHandler.body.data.nodes.getDataSet()
    window.visnetwork.stopSimulation()
    selections = (window.visnetwork.getSelection()).nodes
    if not selections.length  #no selections, apply to all nodes
      nodes.forEach (node)->
        node.label = labelForVertex(node.element,key)
        nodes.update {id: node.id, label: node.label}
    else # apply to selected nodes only
      selections.forEach (nodeID)->
        node = nodes.get(nodeID)
        node.label = labelForVertex(node.element,key)
        nodes.update {id: node.id, label: node.label}
    window.visnetwork.startSimulation()

  $(".useLabelPrefix").prop('checked', true)
  Session.set 'useLabelPrefix', true
  $(".useLabelPrefix").change ->
    state = $(".useLabelPrefix").prop('checked')
    Session.set 'useLabelPrefix', state
    updateNodelabels()



  #------------------Select IF support
  $("#nodeLabelSelector").change ->
    sel = $("#nodeLabelSelector").val()
    if sel == 'all vertices'
      $('#elementSelector').val ('{"type": "vertex"}')
    else
      if sel == 'all edges'
        $('#elementSelector').val ('{"type": "edge"}')
      else
        $('#elementSelector').val ('"'+$("#nodeLabelSelector").val()+'"')
    $('#elementSelector').trigger('input')


  Session.set 'elementSelector', null  # null means select nothing

  window.updateSelectedElements = (ctxt) ->
    Session.set 'elementSelector', ctxt
    try
      selector = JSON.parse(Session.get 'elementSelector')
      $('#elementSelector')[0].style.color = 'black'
    catch error
      $('#elementSelector')[0].style.color = 'red'     # signal a syntax error with red text
      return
    selectedNodes = selectNodes(selector, window.visnetwork.body.data.nodes._data)
    selectedEdges = selectEdges(selector, window.visnetwork.body.data.edges._data)
    window.visnetwork.setSelection({nodes: selectedNodes, edges: selectedEdges},{unselectedAll: true, highlightEdges: false})

  selectNodes = (selector, possibles) ->
# options for selection query:   null, id#, labelString, {key:val, key:val...}, [query,query,...]
    selected = []
    if selector == null   # select nothing
      return selected
    if $.isNumeric(selector) && (possibles[selector])    # assume this number is an ID, select for it
      selected.push selector
      return selected
    if _.isString(selector)   # string label selector, convert to object
      selector = {label: selector}
    if $.isPlainObject(selector)    # select all elements with these properties
      possibleProps = ({id: each.id, label: each.element.label, type: each.element.type, props:(each.element.properties)} for each in _.values(possibles))
      possibleValues = []
      for props in possibleProps
        obj = {id: props.id, label: props.label, type: props.type}
        ((obj[key]=props.props[key][0].value) for key in _.keys(props.props))
        possibleValues.push obj
      found = _.where possibleValues, selector
      selected.push f.id for f in found
      return selected
    if $.isArray(selector)    # an array of selectors
      (selected.push (selectNodes each, possibles)) for each in selector
      selected = _.flatten selected
      return selected
    return selected

  selectEdges = (selector, possibles) ->
    # options for selection query:   null, id#, labelString, {key:val, key:val...}, [query,query,...]
    selected = []
    if selector == null   # select nothing
      return selected
    if $.isNumeric(selector) && (possibles[selector])    # assume this number is an ID, select for it
      selected.push selector
      return selected
    if _.isString(selector)   # string label selector, convert to object
      selector = {label: selector}
    if $.isPlainObject(selector)  == 232   # select all elements with these properties
      possibleValues = _.values(possibles)
      found = _.where possibleValues, selector
      selected.push f.id for f in found
      return selected
    if $.isPlainObject(selector)    # select all elements with these properties
      possibleProps = ({id: each.id, label: each.element.label, type: each.element.type, props:(if each.element.properties then each.element.properties else {})} for each in _.values(possibles))
      possibleValues = []
      for props in possibleProps
        obj = {id: props.id, label: props.label, type: 'edge'}
        ((obj[key]=props.props[key]) for key in _.keys(props.props))
        possibleValues.push obj
      found = _.where possibleValues, selector
      selected.push f.id for f in found
      return selected
    if $.isArray(selector)    # an array of selectors
      (selected.push (selectEdges each, possibles)) for each in selector
      selected = _.flatten selected
      return selected
    return selected

  return





  $(".results-graph-fit").click ->
    window.visnetwork.fit()

  #------------------drag multiselect functions----------------------------
  rect = {}
  drag = false
  canvas = window.visnetwork.canvas.frame.canvas
  ctx = canvas.getContext('2d')
  drawingSurfaceImageData = ctx.getImageData(0, 0, canvas.width, canvas.height)


  saveDrawingSurface = ->
    drawingSurfaceImageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
    return

  restoreDrawingSurface = ->
    ctx.putImageData drawingSurfaceImageData, 0, 0
    return

  selectNodesFromHighlight = ->
    nodesIdInDrawing = Session.get('selectedNodes')
    xRange = getStartToEnd(rect.startX, rect.w)
    yRange = getStartToEnd(rect.startY, rect.h)
    allNodes = window.visnetwork.nodesHandler.body.data.nodes.get()
    i = 0
    while i < allNodes.length
      curNode = allNodes[i]
      nodePosition = window.visnetwork.getPositions([ curNode.id ])
      nodeXY = window.visnetwork.canvasToDOM(
        x: nodePosition[curNode.id].x
        y: nodePosition[curNode.id].y)
      if xRange.start <= nodeXY.x and nodeXY.x <= xRange.end and yRange.start <= nodeXY.y and nodeXY.y <= yRange.end
        nodesIdInDrawing.push curNode.id
      i++

    window.visnetwork.selectNodes nodesIdInDrawing
    return

  getStartToEnd = (start, theLen) ->
    if theLen > 0
      ret =
        start: start
        end: start + theLen
    else
      ret =
        start: start + theLen
        end: start
    return ret

  container = $("#mynetwork")
  container.on 'mousemove', (e) ->
    if drag
      restoreDrawingSurface()
      rect.w = e.pageX - (@offsetLeft) - (rect.startX)
      rect.h = e.pageY - (@offsetTop) - (rect.startY)
      ctx.setLineDash [ 5 ]
      ctx.strokeStyle = 'rgb(0, 102, 0)'
      ctx.strokeRect rect.startX, rect.startY, rect.w, rect.h
      ctx.setLineDash []
      ctx.fillStyle = 'rgba(0, 255, 0, 0.2)'
      ctx.fillRect rect.startX, rect.startY, rect.w, rect.h
    return
  container.on 'mousedown', (e) ->
    Session.set('selectedNodes', [])
    if e.button == 2
      if e.shiftKey
        currentSelections = window.visnetwork.getSelectedNodes()
        Session.set('selectedNodes', currentSelections)
      saveDrawingSurface()
      that = this
      rect.startX = e.pageX - (@offsetLeft)
      rect.startY = e.pageY - (@offsetTop)
      drag = true
      container[0].style.cursor = 'crosshair'
    return
  container.on 'mouseup', (e) ->
    if e.button == 2
      restoreDrawingSurface()
      drag = false
      container[0].style.cursor = 'default'
      selectNodesFromHighlight()
    return
  document.body.oncontextmenu = ->
    false




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
    updateNodelabels()

  updateNodelabels = () ->
    key = $("#nodeLabelProperty").val()
    Session.set 'keyForNodeLabel', key
    nodes = window.visnetwork.nodesHandler.body.data.nodes.getDataSet()
    window.visnetwork.stopSimulation()
    selections = (window.visnetwork.getSelection()).nodes
    if not selections.length  #no selections, apply to all nodes
      nodes.forEach (node)->
        node.label = labelForVertex(node.element,key)
        nodes.update {id: node.id, label: node.label}
    else # apply to selected nodes only
      selections.forEach (nodeID)->
        node = nodes.get(nodeID)
        node.label = labelForVertex(node.element,key)
        nodes.update {id: node.id, label: node.label}
    window.visnetwork.startSimulation()

  $(".useLabelPrefix").prop('checked', true)
  Session.set 'useLabelPrefix', true
  $(".useLabelPrefix").change ->
    state = $(".useLabelPrefix").prop('checked')
    Session.set 'useLabelPrefix', state
    updateNodelabels()



  #------------------Select IF support
  $("#nodeLabelSelector").change ->
    $('#elementSelector').val ('"'+$("#nodeLabelSelector").val()+'"')
    $('#elementSelector').trigger('input')


  Session.set 'elementSelector', null  # null means select nothing

  window.updateSelectedElements = (ctxt) ->
    Session.set 'elementSelector', ctxt
    try
      selector = JSON.parse(Session.get 'elementSelector')
      $('#elementSelector')[0].style.color = 'black'
    catch error
      $('#elementSelector')[0].style.color = 'red'     # signal a syntax error with red text
      return
    selectedNodes = selectNodes(selector, window.visnetwork.body.data.nodes._data)
    selectedEdges = selectEdges(selector, window.visnetwork.body.data.edges._data)
    window.visnetwork.setSelection({nodes: selectedNodes, edges: selectedEdges},{unselectedAll: true, highlightEdges: false})

  selectNodes = (selector, possibles) ->
# options for selection query:   null, id#, labelString, {key:val, key:val...}, [query,query,...]
    selected = []
    if selector == null   # select nothing
      return selected
    if $.isNumeric(selector) && (possibles[selector])    # assume this number is an ID, select for it
      selected.push selector
      return selected
    if _.isString(selector)   # string label selector, convert to object
      selector = {label: selector}
    if $.isPlainObject(selector)    # select all elements with these properties
      possibleProps = ({id: each.id, label: each.element.label, type: each.element.type, props:(each.element.properties)} for each in _.values(possibles))
      possibleValues = []
      for props in possibleProps
        obj = {id: props.id, label: props.label, type: props.type}
        ((obj[key]=props.props[key][0].value) for key in _.keys(props.props))
        possibleValues.push obj
      found = _.where possibleValues, selector
      selected.push f.id for f in found
      return selected
    if $.isArray(selector)    # an array of selectors
      (selected.push (selectNodes each, possibles)) for each in selector
      selected = _.flatten selected
      return selected
    return selected

  selectEdges = (selector, possibles) ->
# options for selection query:   null, id#, labelString, {key:val, key:val...}, [query,query,...]
    selected = []
    if selector == null   # select nothing
      return selected
    if $.isNumeric(selector) && (possibles[selector])    # assume this number is an ID, select for it
      selected.push selector
      return selected
    if _.isString(selector)   # string label selector, convert to object
      selector = {label: selector}
    if $.isPlainObject(selector)    # select all elements with these properties
      possibleValues = _.values(possibles)
      found = _.where possibleValues, selector
      selected.push f.id for f in found
      return selected
    if $.isArray(selector)    # an array of selectors
      (selected.push (selectEdges each, possibles)) for each in selector
      selected = _.flatten selected
      return selected
    return selected

  return

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

selectNeighborsToAdd = (currentSelectedNodeIDs,currentSelectedEdgeIDs,allV,allE) ->
  box = bootbox.dialog
    title:'Select neighboring vertices to add to local graph',
    message:'hello',
    buttons:
      confirm:
        label: "Save"
        className: "btn-success"
        callback: ()->
          selectedVerts = []
          verts2Visit = Session.get('verts2Visit')
          for label in Object.keys(verts2Visit)
            labelVerts = _.reject(allV,(node)->
              node['@value'].label != label)
            selectedVerts = _.union(selectedVerts, _.sample(labelVerts, verts2Visit[label]))
          currentSelectedNodeIDs = _.union currentSelectedNodeIDs,(each['@value'].id['@value']+"" for each in selectedVerts)
          nonSelectedNodeIds = _.reject((each['@value'].id+"" for each in allV),(id)->
            _.contains(currentSelectedNodeIDs,id)
          )
          allE = _.reject(allE, (edge)->
            _.contains(nonSelectedNodeIds,edge.inV+"") || _.contains(nonSelectedNodeIds,edge.outV+"")
          )
          addInTheNeighbors(currentSelectedNodeIDs,currentSelectedEdgeIDs,selectedVerts,allE)
  box.find('.bootbox-body').remove()
  Blaze.renderWithData(Template.VisitSelector,() ->
    {allV:allV,allE:allE}
  ,box.find(".modal-body")[0])


addInTheNeighbors = (nodes2Select,edges2Select,allV,allE) ->
  ahn = allHiddenNodeIDs()
  allV = _.reject(allV,(node)->
    _.contains ahn, node.id+""  #make sure its a string2string compare
  )
  (v['@value']['type'] = 'vertex' for v in allV)
  if window.UsingGraphSON3
    nodes = ({id: String(v['@value']['id']['@value']),label: labelForVertexGraphSON3(v['@value'],Session.get 'keyForNodeLabel'), allowedToMoveX: true, allowedToMoveY: true, title: titleForElementGraphSON3(v['@value']), element:v} for v in allV)
  else
    nodes = ({id: String(v.id),label: labelForVertex(v,Session.get 'keyForNodeLabel'), allowedToMoveX: true, allowedToMoveY: true, title: titleForElement(v), element:v['@value']} for v in allV)
  window.visnetwork.nodesHandler.body.data.nodes.update nodes
  ahe = allHiddenEdgeIDs()
  allE = _.reject(allE,(edge)->
    _.contains ahe, edge.id+""    #make sure its a string2string compare
  )
  (e['@value']['type'] = 'edge' for e in allE)
  if window.UsingGraphSON3
    edges = ({id: String(e['@value']['id']['@value']['relationId']), label: e['@value'].label, from: String(e['@value'].outV['@value']), to: String(e['@value'].inV['@value']), title: titleForElementGraphSON3(e['@value']), element:e['@value']} for e in allE)
  else
    edges = ({id: String(e.id), label: e.label, from: String(e.outV), to: String(e.inV), title: titleForElement(e), element:e} for e in allE)
  window.visnetwork.edgesHandler.body.data.edges.update edges
  for vert in nodes
    nodes2Select.push vert.id
  for edge in edges
    edges2Select.push edge.id
  window.visnetwork.setSelection({ nodes: nodes2Select, edges: edges2Select})


scriptForGeneralIngestionFindOrCreate = ()->
  '''
//given arrays of json for verts and edges, generate them into the graph
//verts2FindOrCreate = incoming binding, an map of objects of properties to use to find existing vertices, or to create them if needed, keyed by fake vertID
/* Example:   (needs to be a full description of the vertex in case we need to create it
[
    {label: "Sensor", id: 0, properties:{"sensorID": [{value: "v000000ktsmkitch"}]}}
]
*/
//vertsJSON = incoming binding, an array of vertex-structured objects
//edgesJSON = incoming binding, an array of edge-structured objects
//transactionContext = incoming binding, string declaring purpose of graph transaction (comes out in Kafka topic "graphChange")

if (bindings['vertsJSON'] == null) {vertsJSON = []} else {vertsJSON = bindings['vertsJSON']}
if (bindings['edgesJSON'] == null) {edgesJSON = []} else {edgesJSON = bindings['edgesJSON']}
if (bindings['verts2FindOrCreate'] == null) {verts2FindOrCreate = []} else {verts2FindOrCreate = bindings['verts2FindOrCreate']}
if (bindings['transactionContext'] == null) {transactionContext = "unlabeled transaction"} else {transactionContext = bindings['transactionContext']}

vMap = [:]
vMapFull = [:]
eMapFull = [:]
verts2FindOrCreate.collect { json ->
    trav = g.V().hasLabel(json.label)
    json.properties.each { key, val ->
        trav = trav.has(key, val[0].value)
        }
    results = trav.toList()
   if (results.size == 0) {oldV = null} else {oldV = results[0]}
    if (oldV == null){
        //create it
        newV = gg(transactionContext).addV(json.label).next()
        json.properties.each { key, val ->
            gg(transactionContext).V(newV.id()).property(key, val[0].value).next()
            }
    } else {
        //reference it
        newV = oldV
    }
    vMap[json.id] = newV.id()

}


vertsJSON.collect { json ->
    newV = gg(transactionContext).addV(json.label).next()
    vMap[json.id] = newV.id()
    vMapFull[json.id] = newV
    json.properties.each { key, val ->
        gg(transactionContext).V(newV.id()).property(key, val[0].value).next()
}}
edgesJSON.collect { json ->
    fromID = vMap[json.outV] ? vMap[json.outV] : json.outV
    toID = vMap[json.inV] ? vMap[json.inV] : json.inV
    newEdge=gg(transactionContext).V(fromID).addE(json.label).to(g.V(toID)).next()
    eMapFull[json.id] = newEdge
    json.properties.collect { key, val ->
        gg(transactionContext).E(newEdge.id()).property(key, val.value).next()
}}
//answer the maps of old element ids to new elements
[vMap: vMap, vertMap: vMapFull, edgeMap: eMapFull]
  '''