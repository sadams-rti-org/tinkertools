Template.OtherGraphButtons.rendered = ->
  $(".graph-script-file-import").click ->
    bootbox.dialog
      title: "Select a script file to be uploaded into this graph only"
      message: '<input type="file" id="fileName" onchange="startRead()"/>Preview:<textarea id="fileContents" />'
      buttons:
        success:
          label: "Import"
          className: "btn-success"
          callback: ()->
            try
              objs = JSON.parse $('#fileContents').val()
            catch e
              alert 'Syntax error in upload file - Expecting JSON'
              debugger
              return
            (each.userID = Session.get('userID')) for each in objs
            (each.graphName = Session.get('graphName')) for each in objs
            (each.serverURL = Session.get('serverURL')) for each in objs
            (each.tinkerPopVersion = Session.get('tinkerPopVersion')) for each in objs
            if (Session.get 'serverURL') == window.BluemixGraphService
              (each.bluemixAPI = window.bluemixAPI) for each in objs
              (each.bluemixUsername = window.bluemixUsername) for each in objs
              (each.bluemixPassword = window.bluemixPassword) for each in objs
            Scripts.insert each for each in objs
            console.log objs

  $(".graph-script-file-export").click ->
    objs = Scripts.find({userID: Session.get('userID'),serverURL: Session.get('serverURL'), graphName: Session.get('graphName')}).fetch()
    delete each._id for each in objs
    delete each.bluemixAPI for each in objs
    delete each.bluemixUsername for each in objs
    delete each.bluemixPassword for each in objs
    data = [JSON.stringify objs,null, 4]
    blob = new Blob(data, {type: "application/json;charset=utf-8"})
    saveAs(blob,'gremlin-scripts-from-'+Session.get('graphName')+'.json')

  $(".graph-file-import-form").fileupload({url:'/upload'})
  $(".graphML-file-import").click ->
    bootbox.dialog
      title: "Select a GraphML file to be uploaded into this graph"
      message: '<input type="file" id="fileName" onchange="window.fileSelected(this.files)"/>Preview:<textarea id="fileContents" />'  #Blaze.toHTML(Template.GraphUploadPopUp)
      buttons:
        success:
          label: "Upload and Install"
          className: "btn-success"
          callback: ()->
            #NProgress.configure({ parent: '.progress-goes-here', showSpinner: true,})
            #NProgress.start()
            formData = new FormData()
            for file in window.FilesToUpload
              uploadName = file.name
              formData.append('file', file, uploadName)
              request = new XMLHttpRequest()
              request.open("POST", 'http://'+window.thisServerAddress+"/upload")
              console.log 'uploading file',file.name
              request.send(formData)
              Meteor.call 'onceFileExistsOnServer', window.thisServerAddress, file.name, (er,rs)->
                if rs
                  uploadNames = (each.name for each in window.FilesToUpload)
                  if uploadNames.length > 0
                    script = "filesToUpload="+(JSON.stringify uploadNames)+"\n
                      filesToUpload.each{fileName->\n
                        g.loadGraphML('http://"+window.thisServerAddress+"/files/'+fileName)\n
                        println 'Finished loading '+fileName\n
                      }"
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
                          callback(results)
                      request =
                        requestId: uuid.new(),
                        op:"eval",
                        processor:"",
                        args:{gremlin: script, bindings: {}, language: "gremlin-groovy"}
                      startTime = Date.now()
                      window.socketToJanus.send(JSON.stringify(request))
                    else
                      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'),(Session.get 'graphName'),'Built-in GraphML Loader',script, (er,rs)->
                        console.log er,rs
                        if er
                          alert 'Failed to load file, try again, or check file'
                        if rs.success == true
                          window.deleteFilesOnServer rs.results
                          #NProgress.done()
                        else
                          #NProgress.done()
                          debugger
                else
                  #NProgress.done()
                  debugger

  $(".graphSON-file-import").click ->   #NOTE this implementation assumes the target graph can reach out of port 80 to the tinkertools server, be sure of the firewall on the graph server
    bootbox.dialog
      title: "Select a GraphSON file to be uploaded into this graph"
      message: '<input type="file" id="fileName" onchange="window.fileSelected(this.files)"/>Preview:<textarea id="fileContents" />'  #Blaze.toHTML(Template.GraphUploadPopUp)
      buttons:
        success:
          label: "Upload and Install"
          className: "btn-success"
          callback: ()->
            #NProgress.configure({ parent: '.progress-goes-here', showSpinner: true,})
           # NProgress.start()
            formData = new FormData()
            for file in window.FilesToUpload
              uploadName = file.name
              formData.append('file', file, uploadName)
              request = new XMLHttpRequest()
              request.open("POST", 'http://'+window.thisServerAddress+"/upload")
              console.log 'uploading file',file.name
              request.send(formData)
              Meteor.call 'onceFileExistsOnServer', window.thisServerAddress, file.name, (er,rs)->
                if rs
                  uploadNames = (each.name for each in window.FilesToUpload)
                  if uploadNames.length > 0
                    script = "filesToUpload="+(JSON.stringify uploadNames)+"\n
                      filesToUpload.each{fileName->\n
                        g.loadGraphSON('http://"+window.thisServerAddress+"/files/'+fileName)\n
                        println 'Finished loading '+fileName\n
                      }"
                    console.log script
                    if (Session.get "usingWebSockets")
                      window.socketToJanus.onmessage = (msg) ->
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
                        args:{gremlin: script, bindings: {}, language: "gremlin-groovy"}
                      startTime = Date.now()
                      window.socketToJanus.send(JSON.stringify(request))
                    else
                      Meteor.call 'runScript', (Session.get 'userID'),(Session.get 'serverURL'),(Session.get 'tinkerPopVersion'),(Session.get 'graphName'),'Built-in GraphSON Loader',script, (er,rs)->
                        console.log er,rs
                        if er
                          alert 'Failed to load file, try again, or check file'
                        if rs.success == true
                          window.deleteFilesOnServer rs.results
                        else
                          #NProgress.done()
              #NProgress.done()

  $('.csv-files-import').click ->
    bootbox.dialog
      title: "Select a CSV Ingestion Template and one or more CSV files to Ingest"
      message: '<input type="file" id="csv-template-file" onchange="window.csvTemplateFileSelected(this.files)" />Preview of CSV Ingest Template:<textarea id="csvTemplateFileContents" /><input type="file" id="files" onchange="window.filesSelected(this.files)" multiple/>Preview:<textarea id="fileContents" />'
      buttons:
        success:
          label: "Upload and Install"
          className: "btn-success"
          callback: ()->
            #NProgress.configure({ parent: '.progress-goes-here', showSpinner: false,})
            #NProgress.start()
            Session.set 'totalRecordsParsed', 0
            $('#csv-template-file').parse
              config:
                header: true
                skipEmptyLines:true
                chunk: (chunk, handle)->
                  #NProgress.inc()
                  file = handle.fileBeingParsed
                  console.log chunk
                  window.CSVIngestTemplate = processCSVTemplateRows(chunk.data)
              before: (file, inputElem)->
                console.log 'Parsing CSV template file:', file.name
                Session.set 'fileBeingParsed', file.name
                Session.set 'recordsParsed',0
              complete: (file)->
                if file
                  console.log 'Completed',file.name
                console.log 'first...'
                await firstPass()
                console.log 'second'
                await midPass()
                console.log 'adding twigs and leaves'
                window.prom = wsp.open()
                debugger
                $('#files').parse
                  config:
                    header: true
                    skipEmptyLines:true
                    chunk: (results, parser)->
                      console.log "parsed chunk = ",results.data
                      ingestCSVRecordsUsingTemplate(results.data, window.CSVIngestTemplate, prom,(err,res)->
                        #console.log "Result of ingest = ",res
                      )
                    complete: (results,file)->
                      if file
                        console.log 'Completed',file.name
                      #prom.then((response)-> console.log "Finished with promises = ", response)


import WebSocketAsPromised from 'websocket-as-promised'
window.wsap = WebSocketAsPromised
wsUrl = "ws://localhost:8182/gremlin"
window.wsp = new WebSocketAsPromised(wsUrl,
  packMessage: (data)->
    JSON.stringify(data)
  unpackMessage: (message)->
    JSON.parse(message)
  attachRequestId: (data, requestId)->
    Object.assign({requestId: requestId}, data)
  extractRequestId: (data)->
    data && data.requestId
)
window.wsp.onMessage.addListener((message)-> console.log JSON.parse(message))



ingestCSVRecordsUsingTemplate = (rows, template, priorPromise, callback) ->
  requests = []
  for row in rows
    #console.log "row = ",row
    #process verts first
    verts2Create = []
    verts2FindOrCreate = []
    for k1,vTemp of template.verts
      vert = {label: vTemp.label, id: Number(vTemp.uid), properties:{_class: [{value:vTemp._class}]}, propsToMatch:{}, propsToAdd:{}}
      for k2,prop of vTemp.props
        incomingValue = row[prop.property]
        if incomingValue
          if prop.dataType == "String" then outgoingValue = incomingValue.toString()
          if prop.dataType == "Single" then outgoingValue = Number(incomingValue)
          if prop.dataType == "Double" then outgoingValue = Number(incomingValue)
          if prop.dataType == "Bool" then outgoingValue = JSON.parse(incomingValue.toLowerCase())
          vert.properties[prop.property] = [{value: outgoingValue}]
          if vert.properties[prop.findIt] == "TRUE"
            vert.propsToMatch[prop.property] = [{value: outgoingValue}]
          else
            vert.propsToAdd[prop.property] = [{value: outgoingValue}]
      if vert.propsToMatch == {}
        verts2Create.push vert
      else
        verts2FindOrCreate.push vert
    #process edges
    edges2FindOrCreate = []
    for k1,eTemp of template.edges
      edge = {label: eTemp.label, id: Number(eTemp.uid), properties:{}, outV: Number(eTemp.fromV), inV: Number(eTemp.toV)}
      for k2,prop of eTemp.props
        incomingValue = row[prop.property]
        if incomingValue
          if prop.dataType == "String" then outgoingValue = incomingValue.toString()
          if prop.dataType == "Single" then outgoingValue = JSON.parse(incomingValue)
          if prop.dataType == "Double" then outgoingValue = JSON.parse(incomingValue)
          if prop.dataType == "Bool" then outgoingValue = JSON.parse(incomingValue.toLowerCase())
          edge.properties[prop.property] = outgoingValue
      edges2FindOrCreate.push edge
      #NOTE that edges2Create is ignored in this version
    bindings = {verts2Create: verts2Create, verts2FindOrCreate: verts2FindOrCreate, edges2FindOrCreate: edges2FindOrCreate, edges2Create:[], transactionContext: "ingesting from CSV"}
    #console.log "bindings ready to send = ",bindings
    if (Session.get "usingWebSockets")
      request =
        op:"eval",
        processor:"",
        args:{gremlin: ingestionScript(), bindings: bindings, language: "gremlin-groovy"}
      requests.push JSON.parse(JSON.stringify(request))
    else
      Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'CSV Ingester', ingestionScript(), bindings, (error,result)->
        callback(result.results)
  #console.log "Requests = ",requests
  wait = (ms)->
    new Promise((resolve)-> setTimeout(resolve,ms))
  sendIt = (req)->
    await wait(100)
    wsp.sendRequest(req,{requestId: uuid.new()})

  respondIt = (response)->
    console.log  "resp=",response
  for req in requests
    window.prom = window.prom.then(sendIt.bind(null,req))
    window.prom = window.prom.then(respondIt)



firstPass = ()->
  #First pass to locate and find/create roots and low branch verts
  new Promise (resolve) ->
    window.verts2EnsureCreation = {}
    $('#files').parse
      config:
        header: true
        skipEmptyLines:true
        step: (results, parser)->
          row = results.data[0]
          collectRootsAndLowBranchVerts(row, window.CSVIngestTemplate)
        complete: (results,file)->
          resolve()

midPass = ()->
  new Promise (resolve) ->
    ingestVertices(Object.values(window.verts2EnsureCreation), (err,res)->
      console.log res
      resolve()
    )

ingestVertices = (verts2Create,callback)->
  window.prom = wsp.open()
  bindings = {verts2Create: verts2Create, verts2FindOrCreate: [], edges2FindOrCreate: [], edges2Create:[], transactionContext: "ingesting from CSV"}
  console.log bindings
  if (Session.get "usingWebSockets")
    request =
      requestId: uuid.new(),
      op:"eval",
      processor:"",
      args:{gremlin: ingestionScript(), bindings: bindings, language: "gremlin-groovy"}
    startTime = Date.now()
    wait = (ms)->
      new Promise((resolve)-> setTimeout(resolve,ms))
    sendIt = (req)->
      await wait(100)
      wsp.sendRequest(req,{requestId: uuid.new()})
    respondIt = (response)->
      console.log  "resp=",response
      callback('no err',response)
    window.prom = window.prom.then(sendIt.bind(null,request))
    window.prom = window.prom.then(respondIt)
  else
    Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'CSV Ingester', ingestionScript(), bindings, (error,result)->
      callback(result.results)


collectRootsAndLowBranchVerts = (row, template) ->
  console.log "looking for roots=",row
  #process verts first
  for k1,vTemp of template.verts
    vert = {label: vTemp.label, id: Number(vTemp.uid), properties:{_class: [{value:vTemp._class}]}, propsToMatch:{}, propsToAdd:{}}
    for k2,prop of vTemp.props
      incomingValue = row[prop.property]
      if incomingValue
        if prop.dataType == "String" then outgoingValue = incomingValue.toString()
        if prop.dataType == "Single" then outgoingValue = Number(incomingValue)
        if prop.dataType == "Double" then outgoingValue = Number(incomingValue)
        if prop.dataType == "Bool" then outgoingValue = JSON.parse(incomingValue.toLowerCase())
        vert.properties[prop.property] = [{value: outgoingValue}]
        if prop.findIt == "TRUE"
          vert.propsToMatch[prop.property] = [{value: outgoingValue}]
        else
          vert.propsToAdd[prop.property] = [{value: outgoingValue}]
    if Object.keys(vert.propsToMatch).length == 0
      a=1
    else
      console.log vert
      window.verts2EnsureCreation[vert.label+':'+vert._class+':'+JSON.stringify(vert.propsToMatch)] = vert





ingestionScript = ()->
  """
  //bindings include: {verts2FindOrCreate, edges2FindOrCreate, verts2Create, edges2Create}
  vMap = [:]
  vMapFull = [:]
  eMapFull = [:]
  eMultimatchMap = [:]
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
      vMapFull[json.id] = newV
  }


  verts2Create.collect { json ->
      newV = g.addV(json.label).next()
      vMap[json.id] = newV.id()
      vMapFull[json.id] = newV
      json.properties.each { key, val ->
          g.V(newV.id()).property(key, val[0].value).next()
  }}

  edges2FindOrCreate.collect { json ->
      fromID = vMap[json.outV] ? vMap[json.outV] : json.outV
      toID = vMap[json.inV] ? vMap[json.inV] : json.inV
      /*cases to consider:
          1) edge does not exist....create it and its properties
          2) a single edge exists that matches to/from/label....use it and overwrite/add properties
          3) multiple edges exist that match from/to/label, pick one and overwrite/add properties, and report it in return via eMultimatchMap[ incoming-json-id: chosen existing edge]
      */

      oldEdges = g.V(fromID).outE(json.label).as('e').inV().hasId(toID).select('e').toList()
      if (oldEdges.size() == 0){  //none exists so create a new edge
          newEdge=g.V(fromID).addE(json.label).to(g.V(toID)).next()
          theEdge = newEdge
      } else {
          if (oldEdges.size() == 1){ //only one exists so use it
              theEdge = oldEdges[0]
          } else { //multiple exists so pick first one and use it and record the fact in eMultimatchMap
              theEdge = oldEdges[0]
              eMultimatchMap[json.id] = theEdge
          }
      }

      eMapFull[json.id] = theEdge
      json.properties.collect { key, val ->
          g.E(theEdge.id()).property(key, val.value).next()

  }}
    edges2Create.collect { json ->
        fromID = vMap[json.outV] //? vMap[json.outV] : json.outV
        toID = vMap[json.inV] //? vMap[json.inV] : json.inV


        newEdge=g.V(fromID).addE(json.label).to(g.V(toID)).next()
        eMapFull[json.id] = newEdge
        json.properties.collect { key, val ->
            g.E(newEdge.id()).property(key, val.value).next()
        }}


  //answer the maps of old element ids to new elements
  [vMap: vMap, vertMap: vMapFull, edgeMap: eMapFull, eMultimatchMap: eMultimatchMap]
  """

ingestionScriptWithBatches = ()->
  """
  //given arrays of json for verts and edges, generate them into the graph
  //batches =  incoming binding, an array of bindings for the following
  //verts2FindOrCreate = incoming binding, an map of objects of properties to use to find existing vertices, or to create them if needed, keyed by fake vertID
  /* Example:   (needs to be a full description of the verstex in case we need to create it
  [
      {label: "Sensor", id: 0, properties:{"sensorID": [{value: "v000000ktsmkitch"}]}}
  ]
  */
  //verts2Create = incoming binding, an array of vertex-structured objects
  //edges2Create = incoming binding, an array of edge-structured objects
  //transactionContext = incoming binding, string declaring purpose of graph transaction (comes out in Kafka topic "graphChange")

  batches.collect { bindings ->
      verts2FindOrCreate = bindings.verts2FindOrCreate
      verts2Create = bindings.verts2Create
      edges2Create = bindings.edges2Create
      transactionContext = bindings.transactionContext
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
      verts2Create.collect { json ->
          newV = g.addV(json.label).next()
          vMap[json.id] = newV.id()
          vMapFull[json.id] = newV
          json.properties.each { key, val ->
              g.V(newV.id()).property(key, val[0].value).next()
      }}
      edges2Create.collect { json ->
          fromID = vMap[json.outV] ? vMap[json.outV] : json.outV
          toID = vMap[json.inV] ? vMap[json.inV] : json.inV
          newEdge=g.V(fromID).addE(json.label).to(g.V(toID)).next()
          eMapFull[json.id] = newEdge
          json.properties.collect { key, val ->
              g.E(newEdge.id()).property(key, val.value).next()
      }}
      //answer the maps of old element ids to new elements
      [vertMap: vMapFull, edgeMap: eMapFull]
  }
  """






window.filesSelected = (files)->
  window.FilesToUpload = files
  startRead()

window.csvTemplateFileSelected = (file)->
  window.CSVTemplateFileToUpload = file[0]
  startReadingCSVTemplate()

window.startReadingCSVTemplate = (evt)->
  element = document.getElementById("csv-template-file")
  if element
    if element.files[0].size > 10000000
      return CSVgetAsTextPreview element.files[0]
    else
      return CSVgetAsText element.files[0]

window.CSVgetAsTextPreview = (readFile)->
  reader = new FileReader
  reader.readAsText (readFile.slice(0,10000000)), "UTF-8"
  reader.onload = csvTemplateFileLoaded
window.CSVgetAsText = (readFile)->
  reader = new FileReader
  reader.readAsText (readFile), "UTF-8"
  reader.onload = csvTemplateFileLoaded

window.csvTemplateFileLoaded = (evt)->
  $('#csvTemplateFileContents').val(evt.target.result)



processCSVTemplateRows = (rows) ->
  verts = {}
  edges = {}
  indices = {}
  for row in rows
    if row.type == 'vertex'
      uid = row.uid
      delete row.type
      delete row.uid
      if !verts[uid]
        verts[uid] =
          uid: uid
          type: 'vertex'
          label: row['label/_class']
          _class: row['label/_class']
          props: []
          edges: {}
      if row.edgeLabel1
        verts[uid]['edges'][row.edgeTo1] = row.edgeLabel1
      delete row.edgeLabel1
      delete row.edgeTo1
      if row.edgeLabel2
        verts[uid]['edges'][row.edgeTo2] = row.edgeLabel2
      delete row.edgeLabel2
      delete row.edgeTo2
      if row.edgeLabel3
        verts[uid]['edges'][row.edgeTo3] = row.edgeLabel3
      delete row.edgeLabel3
      delete row.edgeTo3
      if row.edgeLabel4
        verts[uid]['edges'][row.edgeTo4] = row.edgeLabel4
      delete row.edgeLabel4
      delete row.edgeTo4
      if row.edgeLabel5
        verts[uid]['edges'][row.edgeTo5] = row.edgeLabel5
      delete row.edgeLabel5
      delete row.edgeTo5
      delete row['label/_class']

      #handle index decls
      if row.indexName
        if !indices[row.indexName]
          indices[row.indexName] =
            indexName: row.indexName
            indexType: row.indexType
            keys: []
        indices[row.indexName].keys.push
          key: row.property
          dataType: row.dataType
          indexOrder: row.indexOrder
      delete row.indexName
      delete row.indexType
      delete row.indexOrder

      #Now add all the rest of the property attributes
      verts[uid]['props'].push row

    if row.type == 'edge'
      uid = row.uid
      delete row.type
      delete row.uid
      if !edges[uid]
        edges[uid] =
          uid: uid
          type: 'edge'
          label: row['label/_class']
          props: []
      delete row['label/_class']
      if row.fromV
        edges[uid].fromV = row.fromV
        delete row.fromV
      if row.toV
        edges[uid].toV = row.toV
        delete row.toV
      edges[uid]['props'].push row

  #post-process verts to collect simple edges
  nextEdgeId = 1000
  for key,vert of verts
    for eKey,edgeLabel of vert.edges
      edges[nextEdgeId] =
        uid: nextEdgeId
        type: 'edge'
        label: edgeLabel
        fromV: vert.uid
        toV: JSON.parse(eKey)
      nextEdgeId = nextEdgeId + 1

  #post-process the indices to reduce single key cases
  for key,index of indices
    ordered = true
    index.dataType = 'Ordered'
    for key,specs of index.keys
      if !specs.indexOrder
        ordered = false
        index.dataType = index.keys[0].dataType  #assume they are all the same in this case
    if !ordered
      delete index.keys

  result = {
    verts: verts
    edges: edges
    indices: indices
  }
  console.log result
  return result





###  mostly junk


  console.log "Starting 1st pass"
  window.verts2EnsureCreation = {}
  await firstPass()
  console.log "Starting mid pass"
  await midPass()
  console.log "Starting 2nd pass"
  await secondPass()
  console.log "done"



firstPass = ()->
#First pass to locate and find/create roots and low branch verts
new Promise (resolve) ->
  $('#files').parse
    config:
      header: true
      skipEmptyLines:true
      step: (results, parser)->
        row = results.data
        collectRootsAndLowBranchVerts(row, window.CSVIngestTemplate)
      complete: (results,file)->
        resolve()

midPass = ()->
new Promise (resolve) ->
  ingestVertices(Object.values(window.verts2EnsureCreation), (err,res)->
    console.log res
    resolve()
  )

secondPass = ()->
#Second pass to add all high branches and leaf verts
new Promise (resolve) ->
  $('#files').parse
    config:
      header: true
      skipEmptyLines:true
      chunk: (results, parser)->
        ingestCSVRecordsUsingTemplate(results.data, window.CSVIngestTemplate, (err,res)->
          console.log res
        )
      complete: (results,file)->
        if file
          console.log 'Completed',file.name
        resolve()


ingestVertices = (verts2Create,callback)->
bindings = {verts2Create: verts2Create, verts2FindOrCreate: [], edges2FindOrCreate: [], edges2Create:[], transactionContext: "ingesting from CSV"}
console.log bindings
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
    args:{gremlin: ingestionScript(), bindings: bindings, language: "gremlin-groovy"}
  startTime = Date.now()
  window.socketToJanus.send(JSON.stringify(request))
else
  Meteor.call 'runScript', Session.get('userID'), Session.get('serverURL'),(Session.get 'tinkerPopVersion'), Session.get('graphName'),'CSV Ingester', ingestionScript(), bindings, (error,result)->
    callback(result.results)


collectRootsAndLowBranchVerts = (row, template) ->
#process verts first
for k1,vTemp of template.verts
  vert = {label: vTemp.label, id: Number(vTemp.uid), properties:{_class: [{value:vTemp._class}]}, propsToMatch:{}, propsToAdd:{}}
  for k2,prop of vTemp.props
    incomingValue = row[prop.property]
    if incomingValue
      if prop.dataType == "String" then outgoingValue = incomingValue.toString()
      if prop.dataType == "Single" then outgoingValue = Number(incomingValue)
      if prop.dataType == "Double" then outgoingValue = Number(incomingValue)
      if prop.dataType == "Bool" then outgoingValue = JSON.parse(incomingValue.toLowerCase())
      vert.properties[prop.property] = [{value: outgoingValue}]
      if vert.properties[prop.findIt] == "TRUE"
        vert.propsToMatch[prop.property] = [{value: outgoingValue}]
      else
        vert.propsToAdd[prop.property] = [{value: outgoingValue}]
  if vert.propsToMatch == {}
  else
    window.verts2EnsureCreation[vert.label+':'+vert._class+':'+JSON.stringify(vert.propsToMatch)] = vert


###