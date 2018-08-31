Template.LoginOnly.rendered = ->


  #------------------ Utility functions  -----------------------
  #------------------ Button definitions -----------------------


  #------------------ Helpers -----------------------


Template.LoginOnly.helpers

  serverSelected: ->
    (Session.get 'serverURL') != null


  serverURL: ->
    Session.get "serverURL"


  graphName: ->
    Session.get "graphName"
    if (Session.get "serverURL")
      Session.set 'graphNames',['the default graph']
    return Session.get 'graphNames'

  isAdmin: ->
    (Session.get 'userID') == (Session.get 'admin-userID')
  notAdmin: ->
    (Session.get 'userID') != (Session.get 'admin-userID')
  userLoggedIn: ->
    (Session.get 'userID') != null
