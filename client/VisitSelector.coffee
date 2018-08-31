Template.VisitSelector.rendered = ->
  $(".visitVert").prop('checked', true)
  $(".visitVert").change ->
    checked = $(this).prop('checked')
    label2Visit = this.id
    visitCount = JSON.parse($('input#'+label2Visit+'.visitVertCount').val())
    verts2Visit = Session.get('verts2Visit')
    verts2Visit[label2Visit] = visitCount
    if not checked then delete verts2Visit[label2Visit]
    Session.set('verts2Visit',verts2Visit)

  $(".visitVertCount").bind('input', () ->
    label2Count = this.id
    verts2Visit = Session.get('verts2Visit')
    labelChecked = $('input#'+label2Count+'.visitVert.vis-options-checkbox').prop('checked')
    if labelChecked
      verts2Visit[label2Count] = JSON.parse(this.value)
      Session.set('verts2Visit',verts2Visit)
  )

Template.VisitSelector.helpers
  options: ->
     labels = {}
     for vert in this.allV
        if labels[vert.label] != undefined then tot = labels[vert.label] else tot = 0
        labels[vert.label] = tot + 1
     Session.set('verts2Visit',labels)
     _.pairs labels

  label: ->
    @[0]
  count: ->
    @[1]
