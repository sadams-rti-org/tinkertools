Template.TopRow.rendered = ->
  $(".goto-github").click ->
    open(Session.get('githubURL'))

  $(".goto-github-issues").click ->
    open(Session.get('githubIssuesURL'))

  $(".goto-help").click ->
    open('/help')

  $(".goto-demo-video").click ->
    open('/demo-video')

  $(".user-file-export").click ->
    objs = Scripts.find({userID: Session.get('userID')}).fetch()
    delete each._id for each in objs
    delete each.scriptResult for each in objs
    data = [JSON.stringify objs,null, 4]
    blob = new Blob(data, {type: "application/json;charset=utf-8"})
    saveAs(blob,'all-gremlin-scripts-for-'+Session.get('userID')+'.json')

  $(".user-file-import").click ->
    bootbox.dialog
      title: "Select a script file to be uploaded"
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
              return
            (each.userID = Session.get('userID')) for each in objs
            Scripts.insert each for each in objs

Template.TopRow.helpers
  isUserLoggedIn: ->
    (Session.get 'userID') != null
