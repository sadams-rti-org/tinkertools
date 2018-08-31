tests = [
  {url:'http://localhost:8182', expectedVersion: 0, discoveredVersion: null}
]
for test in tests
  Session.set test.url, test

Template.TestTinkerPopVersionDiscovery.rendered = ->
  (Meteor.call 'discoverTinkerPopVersionAt', test.url, (err,dat)->
    if not err
      url = dat[0]
      version = dat[1]
      tst = Session.get url
      tst.discoveredVersion = version
      Session.set url,tst
    ) for test in tests

Template.TestTinkerPopVersionDiscovery.helpers
  results: ->
    JSON.stringify(Session.get(test.url) for test in tests)

