// Generated by CoffeeScript 2.3.1
(function() {
  Template.HomeClassic.rendered = function() {
    Session.set('useLabelPrefix', true);
    Session.set('keyForNodeLabel', "null");
    window.wsConnect = function(wsUri) {
      console.log("connecting to ", wsUri);
      window.socketToJanus = new WebSocket(wsUri + "/gremlin");
      window.socketToJanus.onmessage = function(msg) { //example send method
        var data, json;
        data = msg.data;
        json = JSON.parse(data);
        return window.dispatcher(json);
      };
      window.socketToJanus.onopen = function() {
        console.log("connected to", wsUri);
        return window.WSURL = wsUri;
      };
      return window.socketToJanus.onclose = function() {
        console.log("closed to", window['WSURL'], ' attempting reconnect');
        return setTimeout(window.wsConnect(window['WSURL']), 3000);
      };
    };
    try {
      return window.wsConnect(Session.get("serverURL"));
    } catch (error) {
      return ;
    }
  };

  //*************** utilities

  //********************* Widgets
  Meteor.Spinner.options = {
    lines: 13, // The number of lines to draw
    length: 10, // The length of each line
    width: 5, // The line thickness
    radius: 15, // The radius of the inner circle
    corners: 0.7, // Corner roundness (0..1)
    rotate: 0, // The rotation offset
    direction: 1, // 1: clockwise, -1: counterclockwise
    color: '#fff', // #rgb or #rrggbb
    speed: 1, // Rounds per second
    trail: 60, // Afterglow percentage
    shadow: true, // Whether to render a shadow
    hwaccel: false, // Whether to use hardware acceleration
    className: 'spinner', // The CSS class to assign to the spinner
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    top: 'auto', // Top position relative to parent in px
    left: 'auto' // Left position relative to parent in px
  };

  
  //******************** Buttons

  //******************** Helpers
  Template.HomeClassic.helpers({
    isAdmin: function() {
      return (Session.get('userID')) === (Session.get('admin-userID'));
    },
    notAdmin: function() {
      return (Session.get('userID')) !== (Session.get('admin-userID'));
    },
    userLoggedIn: function() {
      return (Session.get('userID')) !== null;
    },
    graphSelected: function() {
      return (Session.get('graphName')) !== null;
    },
    scriptSelected: function() {
      return (Session.get('scriptName')) !== null;
    },
    scriptResult: function() {
      //(Session.get 'scriptResult')
      return Session.get('showJSONResult');
    },
    graphToShow: function() {
      return Session.get('graphFoundInResults');
    },
    drawingGraph: function() {
      //(Session.get 'drawButtonPressed')
      return Session.get('drawGraphResult');
    }
  });

}).call(this);

//# sourceMappingURL=HomeClassic.js.map
