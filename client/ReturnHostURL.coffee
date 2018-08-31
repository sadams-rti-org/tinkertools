Template.ReturnHostURL.rendered = ->

Template.ReturnHostURL.helpers
  hostURL: ->
    (Session.get 'hostURL')
