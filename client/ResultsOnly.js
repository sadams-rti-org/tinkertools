// Generated by CoffeeScript 2.3.1
(function() {
  Template.ResultsOnly.rendered = function() {
    var container, options;
    //------------------ Widget definition ----------------------
    container = document.getElementById("gremlinResultEditor");
    options = {
      mode: "view",
      modes: ["code", "form", "text", "tree", "view"]
    };
    window.resultsEditor = new JSONEditor(container, options);
    window.resultsEditor.set(Session.get('scriptResults'));
    $("#gremlinResultEditor").height($(window).height());
    return $(window).resize(function() {
      return $("#gremlinResultEditor").height($(window).height());
    });
  };

  Template.ResultsOnly.helpers({
    lastScript: function() {
      return Session.get('scriptCode');
    }
  });

}).call(this);

//# sourceMappingURL=ResultsOnly.js.map
