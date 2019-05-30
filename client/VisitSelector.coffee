Template.VisitSelector.rendered = ->
  $(".visitVert").prop('checked', false)
  $(".visitVert").change ->
    checked = $(this).prop('checked')
    label2Visit = this.id
    id2Visit = label2Visit.replace(/[^0-9a-zA-Z]/g, '')
    visitCount = JSON.parse($('input#'+id2Visit+'.visitVertCount').val())
    verts2Visit = Session.get('verts2Visit')
    verts2Visit[label2Visit] = visitCount
    if not checked then delete verts2Visit[label2Visit]
    Session.set('verts2Visit',verts2Visit)

  $(".visitVertCount").bind('input', () ->
    label2Count = this.id
    id2Count = label2Count.replace(/[^0-9a-zA-Z]/g, '')
    verts2Visit = Session.get('verts2Visit')
    labelChecked = $('input#'+id2Count+'.visitVert.vis-options-checkbox').prop('checked')
    if labelChecked
      verts2Visit[label2Count] = JSON.parse(this.value)
      Session.set('verts2Visit',verts2Visit)
  )

Template.VisitSelector.helpers
  options: ->
    labels = {}
    for vert in this.allV
      if window.UsingGraphSON3
        label = vert['@value'].label
      else
        label = vert.label
      if labels[label] != undefined
        tot = labels[label]
      else
        tot = 0
      labels[label] = tot + 1
    Session.set('verts2Visit',{})
    _.sortBy(_.pairs(labels),(it)->
      return it[0]
    )

  labelID: ->
    @[0].replace(/[^0-9a-zA-Z]/g, '')
  label: ->
    @[0]
  count: ->
    @[1]
