Template.BluemixGraphButtons.rendered = ->
  $(".graph-addBluemix").click ->
    bootbox.dialog
      title: "Provide your Bluemix Graph Service Credentials here:"
      message: (Blaze.toHTML(Template.BluemixGraphServiceCreds))
      buttons:
        success:
          label: "Add"
          className: "btn-success"
          callback: ()->
            newGraphName = $('#newGraphName').val()
            api = $('#bluemixGraphAPI').val()
            user = $('#bluemixUsername').val()
            pass = $('#bluemixPassword').val()
            if newGraphName
              Session.set 'graphNames', []   #flush graph names
              Scripts.insert
                userID: Session.get 'userID'
                serverURL: Session.get 'serverURL'
                graphName: newGraphName
                bluemixUsername: user
                bluemixAPI: api
                bluemixPassword: pass
              Session.set 'graphName', newGraphName
              window.BluemixUsername =  user
              window.BluemixAPI = api
              window.BluemixPassword = pass
              setTimeout( ->
                document.getElementById('graphSelector').value=newGraphName
              ,500)
