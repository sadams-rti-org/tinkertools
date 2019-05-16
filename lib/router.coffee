Router.route('/', ()->
  me = this
  Meteor.call 'getEnvironmentVariable','EMBEDDED_GRAPH_SERVER_URL',(err,result)->
    if result != undefined
      Session.set 'serverURL', result
      Session.set 'tinkerPopVersion','3'
      Session.set 'graphName','the default graph'
      me.render 'HomeEmbedded'
    else
      me.render 'HomeClassic'
  where: 'server')

Router.route('/Tools', ()->
  @render 'Tools'
  where: 'server')

Router.route('/HomeClassic', ()->
  @render 'HomeClassic'
  where: 'server')

Router.route('/Embedded', ()->
  me = this
  if @params.query.serverURL
    Session.set 'serverURL',@params.query.serverURL
    Session.set 'tinkerPopVersion','3'
    Session.set 'graphName','the default graph'
    me.render 'HomeEmbedded'
  else
    me.render 'HomeClassic'
  where: 'server')

Router.route('/testTinkerPopVersionDiscovery', ()->
  @render 'TestTinkerPopVersionDiscovery'
  where: 'server')

Router.route('/help', ()->
  @render 'Help'
  where: 'server')

Router.route('/demo-video', ()->
  @render 'DemoVideo'
  where: 'server')

Router.route('/results', ()->
  Session.set 'scriptResults',JSON.parse(@params.query.json)
  console.log @params.query
  Session.set 'scriptCode',@params.query.script
  @render 'ResultsOnly',
    data: @params.query.json
  where: 'server')

Router.route('/hostURL', ()->
  url = (Meteor.absoluteUrl()).slice(7,-1)
  if (url.slice(-5) == ':3000')
    url = url.slice(0,-5)
  Session.set('hostURL',url)
  @render 'ReturnHostURL'
  where: 'server')


Router.route('/quikvis', ()->
  console.log @params
  if @params.query.renderingOptions
    Session.set 'renderingOptions',JSON.parse(@params.query.renderingOptions)
  else
    Session.set 'renderingOptions', []
  if @params.query.width
    Session.set 'visWidth',JSON.parse(@params.query.width)
  if @params.query.height
    Session.set 'visHeight',JSON.parse(@params.query.height)
  serverURL = @params.query.serverURL
  Session.set 'serverURL',serverURL
  Session.set "usingWebSockets",(serverURL.slice(0,5) == "ws://")
  Session.set 'tinkerPopVersion',3
  window.UsingGraphSON3 = JSON.parse(@params.query.graphSON3)
  Session.set 'scripts',JSON.parse(@params.query.scripts)
  Session.set 'positions',JSON.parse(@params.query.positions)
  Session.set 'graphName',"the default graph"
  if @params.query.visOptions
    Session.set 'visOptions',JSON.parse(@params.query.visOptions)
  #console.log @params.query
  #console.log @params.query
  @render 'QuikVis',
    data: @params.query.renderingOptions
  where: 'server')


Router.route('/quikvisiframe', ()->
  if @params.query.renderingOptions
    Session.set 'renderingOptions',JSON.parse(@params.query.renderingOptions)
  else
    Session.set 'renderingOptions', []
  if @params.query.width
    Session.set 'visWidth',JSON.parse(@params.query.width)
  if @params.query.height
    Session.set 'visHeight',JSON.parse(@params.query.height)
  serverURL = @params.query.serverURL
  Session.set 'serverURL',serverURL
  Session.set "usingWebsSockets",(serverURL.slice(0,5) == "ws://")
  Session.set 'tinkerPopVersion',3
  Session.set 'scripts',JSON.parse(@params.query.scripts)
  Session.set 'graphName',"the default graph"
  if @params.query.visOptions
    Session.set 'visOptions',JSON.parse(@params.query.visOptions)
  #console.log @params.query
  @render 'QuikVisIFrameOnly',
    data: @params.query.renderingOptions
  where: 'server')


Router.route('/quikvisminimal', ()->
  if @params.query.width
    Session.set 'visWidth',JSON.parse(@params.query.width)
  if @params.query.height
    Session.set 'visHeight',JSON.parse(@params.query.height)
  if @params.query.renderingOptions
    Session.set 'renderingOptions',JSON.parse(@params.query.renderingOptions)
  else
    Session.set 'renderingOptions', []
  serverURL = @params.query.serverURL
  Session.set 'serverURL',serverURL
  Session.set "usingWebSockets",(serverURL.slice(0,5) == "ws://")
  Session.set 'tinkerPopVersion',3
  Session.set 'scripts',JSON.parse(@params.query.scripts)
  Session.set 'graphName',"the default graph"
  if @params.query.visOptions
    Session.set 'visOptions',JSON.parse(@params.query.visOptions)
  #console.log @params.query
  @render 'QuikVisIFrameOnlyMinimal',
    data: @params.query.renderingOptions
  where: 'server')



