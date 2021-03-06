// Generated by CoffeeScript 2.3.1
(function() {
  Template.AdminTools.rendered = function() {
    $(".all-user-file-export").click(function() {
      var blob, data, each, j, k, len, len1, objs;
      alert('here');
      objs = Scripts.find({}).fetch();
      for (j = 0, len = objs.length; j < len; j++) {
        each = objs[j];
        delete each._id;
      }
      for (k = 0, len1 = objs.length; k < len1; k++) {
        each = objs[k];
        delete each.scriptResult;
      }
      data = [JSON.stringify(objs, null, 4)];
      blob = new Blob(data, {
        type: "application/json;charset=utf-8"
      });
      return saveAs(blob, 'tinkertools-user-db.json');
    });
    return $(".all-user-file-import").click(function() {
      return bootbox.dialog({
        title: "Select a tinkertools db file to be uploaded (JSON)",
        message: '<input type="file" id="fileName" onchange="startRead()"/>Preview:<textarea id="fileContents" />',
        buttons: {
          success: {
            label: "Import",
            className: "btn-success",
            callback: function() {
              var e, each, j, len, objs, results;
              try {
                objs = JSON.parse($('#fileContents').val());
              } catch (error) {
                e = error;
                alert('Syntax error in upload file - Expecting JSON');
                return;
              }
              results = [];
              for (j = 0, len = objs.length; j < len; j++) {
                each = objs[j];
                results.push(Scripts.insert(each));
              }
              return results;
            }
          }
        }
      });
    });
  };

  //******************** Helpers
  Template.AdminTools.helpers({
    userNames: function() {
      var all, allEntries, each, nodups;
      allEntries = Scripts.find().fetch();
      all = (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = allEntries.length; j < len; j++) {
          each = allEntries[j];
          results.push(each.userID);
        }
        return results;
      })();
      nodups = all.filter(function(v, i, a) {
        return a.indexOf(v) === i;
      });
      if (nodups.length === 0) {
        return [];
      }
      return nodups;
    },
    userName: function() {
      return this;
    },
    userAccountNames: function() {
      var allEntries;
      allEntries = Meteor.call('allUserIDs', function(err, res) {
        return Session.set('allUserIDs', res);
      });
      return Session.get('allUserIDs');
    },
    userAccountName: function() {
      return this;
    },
    usersOnline: function() {
      return Meteor.users.find({
        "status.online": true
      });
    },
    userOnline: function() {
      return this.emails[0].address;
    },
    serverURLs: function() {
      var all, allEntries, each, nodups;
      allEntries = Scripts.find().fetch();
      all = (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = allEntries.length; j < len; j++) {
          each = allEntries[j];
          results.push(each.serverURL);
        }
        return results;
      })();
      nodups = all.filter(function(v, i, a) {
        return a.indexOf(v) === i;
      });
      if (nodups.length === 0) {
        return [];
      }
      return nodups;
    },
    serverURL: function() {
      return this;
    }
  });

}).call(this);

//# sourceMappingURL=AdminTools.js.map
