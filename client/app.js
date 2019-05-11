// Generated by CoffeeScript 2.3.1
(function() {
  Session.set('user', null);

  Session.set('serverURL', null);

  Session.set('graphName', null);

  Session.set('scriptName', null);

  Session.set('scriptResult', null);

  Session.set('graphRenderingStatus', 'Run script first');

  Session.set('graphToShow', {
    nodes: [],
    edges: []
  });

  Session.set('retrieveVerticesAsNeeded', true);

  Session.set('drawCurvedEdges', false);

  Session.set('drawEdgeLabels', true);

  Session.set('drawEdges', true);

  Session.set('examples-userID', 'examples@tinkertools.com'); //password examples

  Session.set('admin-userID', 'admin@tinkertools.com'); //password adminadmin

  Session.set('queryTime', 'N/A');

  Session.set('elapsedTime', 'N/A');

  Session.set('runStatus', 'Ready');

  Session.set('githubURL', 'https://github.com/ssadams11/tinkertools');

  Session.set('githubIssuesURL', 'https://github.com/ssadams11/tinkertools/issues');

  Session.set('graphFoundInResults', false);

  Session.set('drawButtonPressed', false);

  Session.set('elapsedRenderTime', '');

  Session.set('usingWebSockets', false);

  Session.set('versionNumber', '3.2.3');

  Meteor.subscribe('scripts');

  Meteor.subscribe('userStatus');

  Tracker.autorun(function() {
    var userID;
    if (Meteor.user()) {
      // login handler
      userID = Meteor.user().emails[0].address;
      return Session.set('userID', userID);
    } else {
      // logout handler
      return Session.set('userID', null);
    }
  });

  /*
Meteor._reload.onMigrate = ->
  return [false]
*/

}).call(this);

//# sourceMappingURL=app.js.map
