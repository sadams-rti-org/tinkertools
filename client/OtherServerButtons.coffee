Template.OtherServerButtons.rendered = ->

  $(".server-deleteURL").click ->
    bootbox.confirm
      message: "Are you sure you want to delete all your scripts for all graphs on "+Session.get('serverURL')+"?"
      callback: (answer)->
        if answer
          Meteor.call 'removeURL',Session.get('userID'),Session.get('serverURL')
          Session.set 'serverURL', null
          setTimeout( ->
            document.getElementById('serverSelector').value=''
          ,500)

#------------------ Helpers -----------------------


Template.OtherServerButtons.helpers

  notTP3: ->
    (Session.get 'tinkerPopVersion') != '3'
  notBluemix: ->
    (Session.get 'serverURL') != window.BluemixGraphService
