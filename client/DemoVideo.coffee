Template.DemoVideo.rendered = ->
  $(".goto-gitlab").click ->
    open(Session.get('gitLabURL'))

  $(".goto-gitlab-issues").click ->
    open(Session.get('gitLabIssuesURL'))

