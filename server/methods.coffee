

Meteor.startup ->

Meteor.methods
  runScript: (userID, serverURL, tinkerPopVersion, usingWebSockets, scriptName, script, bindings)->
    loggingScript = 'println "Executing script: ['+scriptName+'] "\n'+script
    sendScript = encodeURIComponent(escapeDollarSignInStrings(script))
    if userID && serverURL && script
      console.log "version =  ", tinkerPopVersion
      if tinkerPopVersion == '3'
        args =
          data:
            gremlin: script
            bindings: bindings
          headers:
            "Content-Type": 'application/json'
        console.log "bindings = ",JSON.stringify(bindings)
        console.log "script = ",loggingScript
        try
          response = HTTP.post serverURL, args
          console.log "POST results = ", response
        catch e
          response = e.response
        finally
          #console.log response
          if (response != undefined) && response.statusCode && response.statusCode == 200
            #change all properties that are 15+ digit integers into strings to prevent Javascript from converting to floats and losing their value as IDs
            resultString = response.content
            resultString=resultString.replace( /(:[ ]?)\d{15,9999}/g, (x)->
              y = x.replace(/\D/g,'')
              return ': "'+y+'"')
            resultJSON = JSON.parse resultString
            if resultJSON == null
              resultJSON = {results:[null],success:'???',queryTime:'N/A'}
            if resultJSON.result == null
              length = 1
              resultJSON.result = [null]
            else
              #console.log resultJSON.result.data
              length = resultJSON.result.data.length
              console.log 'success:', resultJSON.status.code == 200, ' queryTime:', 'Not Available from Service', ' results.length:', length
              final = {results: resultJSON.result.data, success: resultJSON.status.code==200, queryTime:'Not Available from Service'}
              return final
          else
            return {results: response, success:'Error',queryTime:'N/A'}

  getGraphsOnServer: (serverURL)->
    if serverURL
      response = HTTP.get serverURL+'/graphs'
      return response.data.graphs
    else
      []

  removeScript: (userID,serverURL,graphName,scriptName)->
    Scripts.remove
      userID: userID
      serverURL: serverURL
      graphName: graphName
      scriptName: scriptName

  removeURL: (userID,serverURL)->
    Scripts.remove
      userID: userID
      serverURL: serverURL

  updateScript: (selector, modifier)->
    Scripts.update selector, modifier

  getEntireGraph: (serverURL,graphName) ->
    url = serverURL+'/graphs/'+graphName+'/tp/gremlin?script=[g.V(),g.E()]'
    console.log url
    resp = HTTP.get url
    if resp.data.success
      vs = resp.data.results[0]
      es = resp.data.results[1]
      nodes = ({id: String(v._id), x: chance.floating({min:0,max:100}), y: chance.floating({min:0,max:100}), size:1} for v in vs)
      edges = ({id: String(e._id), label: e._label, source: String(e._outV), target: String(e._inV)} for e in es)
      g = {nodes: nodes, edges: edges}
    else
      g = trigraph()
    return g

  allUserIDs: ->
    allEntries = Meteor.users.find({}).fetch()
    debugger
    all = (each.emails[0].address for each in allEntries)
    nodups = all.filter (v, i, a)->
      a.indexOf(v) == i
    if nodups.length == 0
      return []
    return nodups

  deleteGraphFile: (fileName)->
    fs = Meteor.npmRequire 'fs'
    fs.unlink(process.env.PWD + "/.private/graphs/"+fileName)

  deleteGraphFiles: (fileNames)->
    fs = Meteor.npmRequire 'fs'
    for fileName in fileNames
      fs.unlink(process.env.PWD + "/.private/graphs/"+fileName)

  fileExistsOnServer: (serverAddress, fileName)->
    request = 'http://'+serverAddress+"/exists/"+fileName
    console.log "request", request
    try
      response = HTTP.get(request)
    catch e
      response = e.response
    finally
      if response.statusCode && response.statusCode == 200
        console.log "file exists!"
        return true
      else
        console.log "file does not exist!"
        return false

  onceFileExistsOnServer: (serverAddress, fileName)->
    request = 'http://'+serverAddress+"/exists/"+fileName
    console.log "request", request
    doesNotExist = true
    while doesNotExist
      try
        response = HTTP.get(request)
      catch e
        response = e.response
      finally
        if response.statusCode && response.statusCode == 200
          console.log "file exists!"
          doesNotExist = false
        else
          console.log "file does not exist! trying again"
    return true

  onceFilesExistOnServer: (serverAddress, fileNames)->
    for fileName in fileNames
      request = 'http://'+serverAddress+"/exists/"+fileName
      console.log "request", request
      doesNotExist = true
      while doesNotExist
        try
          response = HTTP.get(request)
        catch e
          response = e.response
          console.log 'error=',response
        finally
          if response.statusCode && response.statusCode == 200
            console.log fileName, "exists!"
            doesNotExist = false
          else
            console.log fileName, "does not exist! trying again"
    return true

   discoverTinkerPopVersionAt: (serverURL)->
     return [serverURL,'3']

  getEnvironmentVariable: (varName)->
    return process.env[varName]

escapeDollarSignInStrings = (script)->
  return script.replace(/\$/g,'\\$')   #escape $ with \$ due to Java string insertion matcher


