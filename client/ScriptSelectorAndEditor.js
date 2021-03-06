// Generated by CoffeeScript 2.3.1
(function() {
  var defaultScript, escapeDollarSignInStrings, scriptCode, scriptURLForStandalone, stripComments;

  defaultScript = 'Select a script from above or add a named script first using the [+Add] button.';

  Template.ScriptSelectorAndEditor.rendered = function() {
    Tracker.autorun(function(e) {
      window.ScriptEditor = AceEditor.instance('scriptEditor');
      if (window.ScriptEditor.loaded === true) {
        e.stop();
        window.ScriptEditor.insert(defaultScript);
        Session.set('scriptCode', '');
        // window.ScriptEditor.setTheme('ace/theme/github')
        window.ScriptEditor.getSession().setMode('ace/mode/groovy');
        window.ScriptEditor.getSession().setUseWrapMode(true);
        return window.ScriptEditor.getSession().setWrapLimitRange();
      }
    });
    $("#scriptSelector").change(function() {
      var scriptName;
      scriptName = $("#scriptSelector").val();
      Session.set('scriptName', scriptName);
      Session.set('scriptResult', null);
      Session.set('queryTime', 'N/A');
      Session.set('elapsedTime', 'N/A');
      Session.set('runStatus', 'Ready');
      Session.set('graphFoundInResults', false);
      Session.set('graphRenderingStatus', 'Run script first');
      Session.set('drawButtonPressed', false);
      Session.set('renderStartTime', null);
      Session.set('scriptCode', scriptCode());
      window.ScriptEditor.setValue(Session.get('scriptCode'));
      if (window.resultsEditor) {
        return window.resultsEditor.set({});
      }
    });
    return $(".script-url-test").click(function() {
      return open(scriptURLForStandalone());
    });
  };

  //------------------ Utility functions  ----------------------
  scriptCode = function() {
    var graphName, record, scriptName, serverURL, userID;
    userID = Session.get('userID');
    serverURL = Session.get('serverURL');
    graphName = Session.get('graphName');
    scriptName = Session.get('scriptName');
    if (userID && serverURL && graphName && scriptName) {
      record = Scripts.findOne({
        userID: userID,
        serverURL: serverURL,
        graphName: graphName,
        scriptName: scriptName
      });
      if (!record) {
        record = Scripts.findOne({
          userID: Session.get('examples-userID'),
          serverURL: serverURL,
          graphName: graphName,
          scriptName: scriptName
        });
      }
      Session.set('scriptCode', record.scriptCode);
      Session.set('scriptResult', null);
      //window.resultsEditor.set {}
      return record.scriptCode;
    } else {
      return '';
    }
  };

  stripComments = function(script) {
    var stripped;
    stripped = script.replace(/(?:\/\*(?:[\s\S]*?)\*\/)|(?:([\s;])+\/\/(?:.*)$)/gm, ''); //strip comments of all kinds
    //stripped = stripped.replace(/\t+/g,' ')  #replace tabs with spaces
    return stripped;
  };

  escapeDollarSignInStrings = function(script) {
    return script.replace(/\$/g, '\\$'); //escape $ with \$ due to Java string insertion matcher
  };

  scriptURLForStandalone = function() {
    var url;
    if ((Session.get('tinkerPopVersion')) === '2') {
      url = (Session.get('serverURL')) + '/graphs/' + (Session.get('graphName')) + '/tp/gremlin?script=' + encodeURIComponent(escapeDollarSignInStrings(stripComments(scriptCode())));
    }
    if ((Session.get('tinkerPopVersion')) === '3') {
      url = (Session.get('serverURL')) + '/?gremlin=' + encodeURIComponent(escapeDollarSignInStrings(stripComments(scriptCode())));
    }
    return url;
  };

  //------------------ Button definitions -----------------------
  Template.ScriptSelectorAndEditor.helpers({
    scriptNames: function() {
      var all, allExamples, allFor, each, exampleScripts, foo, graphName, nodups, nonNulls, serverURL, sorted, userID;
      userID = Session.get('userID');
      serverURL = Session.get('serverURL');
      graphName = Session.get('graphName');
      foo = Session.get('scriptName');
      if (userID && graphName && serverURL) {
        allFor = Scripts.find({
          userID: userID,
          serverURL: serverURL,
          graphName: graphName
        }).fetch();
        all = (function() {
          var j, len, results;
          results = [];
          for (j = 0, len = allFor.length; j < len; j++) {
            each = allFor[j];
            results.push(each.scriptName);
          }
          return results;
        })();
        if ((Session.get('userID')) !== (Session.get('examples-userID'))) {
          allExamples = Scripts.find({
            userID: Session.get('examples-userID'),
            serverURL: serverURL,
            graphName: graphName
          }).fetch();
          exampleScripts = (function() {
            var j, len, results;
            results = [];
            for (j = 0, len = allExamples.length; j < len; j++) {
              each = allExamples[j];
              results.push(each.scriptName);
            }
            return results;
          })();
          all = exampleScripts.concat(all);
        }
        nodups = all.filter(function(v, i, a) {
          return a.indexOf(v) === i;
        });
        if (nodups.length === 0) {
          return [];
        }
        nonNulls = _.reject(nodups, function(x) {
          return !x;
        });
        sorted = _.sortBy(nonNulls, function(e) {
          return e.toLocaleLowerCase();
        });
        return sorted;
      }
    },
    scriptName: function() {
      return this;
    },
    graphSelected: function() {
      return (Session.get('graphName')) !== null;
    },
    scriptSelected: function() {
      return (Session.get('scriptName')) !== null;
    },
    scriptURL: function() {
      return scriptURLForStandalone();
    },
    notBluemix: function() {
      return (Session.get('serverURL')) !== window.BluemixGraphService;
    },
    tinkerPopVersion: function() {
      return Session.get('tinkerPopVersion');
    }
  });

}).call(this);

//# sourceMappingURL=ScriptSelectorAndEditor.js.map
