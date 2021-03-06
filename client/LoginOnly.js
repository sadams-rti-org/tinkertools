// Generated by CoffeeScript 2.3.1
(function() {
  Template.LoginOnly.rendered = function() {};

  //------------------ Utility functions  -----------------------
  //------------------ Button definitions -----------------------

  //------------------ Helpers -----------------------
  Template.LoginOnly.helpers({
    versionNumber: function() {
      return Session.get('versionNumber');
    },
    serverSelected: function() {
      return (Session.get('serverURL')) !== null;
    },
    serverURL: function() {
      return Session.get("serverURL");
    },
    graphName: function() {
      Session.get("graphName");
      if (Session.get("serverURL")) {
        Session.set('graphNames', ['the default graph']);
      }
      return Session.get('graphNames');
    },
    isAdmin: function() {
      return (Session.get('userID')) === (Session.get('admin-userID'));
    },
    notAdmin: function() {
      return (Session.get('userID')) !== (Session.get('admin-userID'));
    },
    userLoggedIn: function() {
      return (Session.get('userID')) !== null;
    }
  });

}).call(this);

//# sourceMappingURL=LoginOnly.js.map
