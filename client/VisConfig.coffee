Template.VisConfig.rendered = ->
  setTimeout( ->
    window.resetVisConfigControls()
    $("#tabsRegion").tabs({active:0, heightStyle: "auto"})
  ,500)



Template.VisConfig.helpers
  dummy: ->
    null

window.updateNodesWithComputedStyling = (exp)->
  alert exp

window.updateEdgesWithComputedStyling = (exp)->
  alert exp

window.resetVisConfigControls = ()->
  conf = window.visnetwork.configurator.moduleOptions
  $("#nodeBorderColorNormal").val conf.nodes.color.border
  $("#nodeBorderColorHighlight").val conf.nodes.color.highlight.border
  $("#nodeBorderColorHover").val conf.nodes.color.hover.border
  $("#nodeBackgroundColorNormal").val conf.nodes.color.background
  $("#nodeBackgroundColorHighlight").val conf.nodes.color.highlight.background
  $("#nodeBackgroundColorHover").val conf.nodes.color.hover.background
  $("#nodeBorderWidth").val conf.nodes.borderWidth
  $("#nodeBorderWidthSelected").val conf.nodes.borderWidthSelected
  $("#nodeLabelFont").val conf.nodes.font.face
  $("#nodeFontSize").val conf.nodes.font.size
  $("#nodeFontBackgroundColor").val conf.nodes.font.background
  $("#nodeFontColor").val conf.nodes.font.color
  $("#nodeFontStrokeColor").val conf.nodes.font.strokeColor
  $("#nodeFontStrokeWidth").val conf.nodes.font.strokeWidth
  $("#nodeLabelHighlightBold").val 'checked', conf.nodes.labelHighlightBold
  $("#nodeLabelAlign").val conf.nodes.font.align
  $("#nodeHide").prop 'checked', conf.nodes.hidden
  $("#nodeShadow").prop 'checked', conf.nodes.shadow
  $("#nodePhysics").prop 'checked', conf.nodes.physics
  $("#nodeXFixed").prop 'checked', conf.nodes.fixed.x
  $("#nodeYFixed").prop 'checked', conf.nodes.fixed.y
  $("#nodeScaleMin").val conf.nodes.scaling.min
  $("#nodeScaleMax").val conf.nodes.scaling.max
  $("#nodeScalingLabel").prop 'checked', conf.nodes.scaling.label.enabled
  $("#nodeShape").val conf.nodes.shape
  $("#nodeShapeRadius").val conf.nodes.shapeProperties.borderRadius
  $("#nodeShapeDashed").val conf.nodes.shapeProperties.borderDashes
  $("#nodeUseImageSize").prop 'checked', conf.nodes.shapeProperties.useImageSize
  $("#nodeShapeSize").val conf.nodes.size

  $("#edgeColorNormal").val conf.edges.color.color
  $("#edgeColorHighlight").val conf.edges.color.highlight
  $("#edgeColorOpacity").val conf.edges.color.opacity
  $("#edgeColorInherit").val conf.edges.color.inherit
  $("#edgeWidth").val conf.edges.width
  $("#edgeSelectedWidth").val conf.edges.selectedWidth
  $("#edgeHoverWidth").val conf.edges.hoverWidth
  $("#edgeLabelFont").val conf.edges.font.face
  $("#edgeFontSize").val conf.edges.font.size
  $("#edgeFontColor").val conf.edges.font.color
  $("#edgeFontBackgroundColor").val conf.edges.font.background
  $("#edgeStrokeFontStrokeColor").val conf.edges.font.strokeColor
  $("#edgeFontStrokeWidth").val conf.edges.font.strokeWidth
  $("#edgeLabelHighlightBold").prop 'checked', conf.edges.labelHighlightBold
  $("#edgeLabelAlign").val conf.edges.font.align
  $("#edgeStrokeFontStrokeColor").val conf.edges.font.strokeColor
  $("#edgeHide").prop 'checked', conf.edges.hidden
  $("#edgeLabelShadow").prop 'checked', conf.edges.shadow.enabled
  $("#edgePhysics").prop 'checked', conf.edges.physics
  $("#edgeScaleMin").val conf.edges.scaling.min
  $("#edgeScaleMax").val conf.edges.scaling.max
  $("#edgeScalingLabel").prop 'checked', conf.edges.scaling.label.enabled
  $("#edgeSmoothEnable").prop 'checked', conf.edges.smooth.type
  $("#edgeSmoothType").val conf.edges.smooth.type
  $("#edgeSmoothForceDirection").val conf.edges.smooth.forceDirection
  $("#edgeSmoothRoundness").val conf.edges.smooth.roundness

  $("#layoutEnabled").prop 'checked', conf.layout.hierarchical.enabled
  $("#hierachicalLevelSeparation").val conf.layout.hierarchical.levelSeparation
  $("#hierachicalNodeSpacing").val conf.layout.hierarchical.nodeSpacing
  $("#hierarchicalTreeSpacing").val conf.layout.hierarchical.treeSpacing
  $("#hierarchicalBlockShifting").prop 'checked', conf.layout.hierarchical.blockShifting
  $("#hierarchicalEdgeMinimization").prop 'checked', conf.layout.hierarchical.edgeMinimization
  $("#hierarchicalParentCentralization").prop 'checked', conf.layout.hierarchical.parentCentralization
  $("#hierarchicalDirection").val conf.layout.hierarchical.direction
  $("#hierarchicalSortMethod").val conf.layout.hierarchical.sortMethod

  $("#interactionDragNodes").prop 'checked', conf.interaction.dragNodes
  $("#interactionDragView").prop 'checked', conf.interaction.dragView
  $("#interactionHideEdgesOnDrag").prop 'checked', conf.interaction.hideEdgesOnDrag
  $("#interactionHideNodesOnDrag").prop 'checked', conf.interaction.hideNodesOnDrag
  $("#interactionHover").prop 'checked', conf.interaction.hover
  $("#interactionHoverConnectedEdges").prop 'checked', conf.interaction.hoverConnectedEdges
  $("#interactionMultiselect").prop 'checked', conf.interaction.multiselect
  $("#interactionNavigationButtons").prop 'checked', conf.interaction.navigationButtons
  $("#interactionSelectable").prop 'checked', conf.interaction.selectable
  $("#interactionSelectConnectedEdges").prop 'checked', conf.interaction.selectConnectedEdges
  $("#interactionZoomView").prop 'checked', conf.interaction.zoomView
  $("#interactionKeyboard").prop 'checked', conf.interaction.keyboard
  $("#interactionToolTipDelay").val conf.interaction.tootipDelay

  $("#manipulationEnabled").prop 'checked', conf.manipulation.enabled
  $("#manipulationInitiallyActive").prop 'checked', conf.manipulation.initiallyActive

  $("#physicsEnabled").prop 'checked', conf.physics.enabled
  $("#physicsSolver").val conf.physics.solver
  $("#physicsMaxVelocity").val conf.physics.maxVelocity
  $("#physicsMinVelocity").val conf.physics.minVelocity
  $("#physicsStabilizationEnabled").prop 'checked', conf.physics.stabilization.enabled
  $("#physicsStabilizationIterations").val conf.physics.stabilization.iterations
  $("#physicsStabilizationUpdateInterval").val conf.physics.stabilization.updateInterval
  $("#physicsStabilizationOnlyDynamicEdges").prop 'checked', conf.physics.stabilization.onlyDynamicEdges
  $("#physicsStabilizationFit").val conf.physics.stabilization.fit
  $("#physicsTimeStep").val conf.physics.timestep
  $("#physicsAdaptiveTimeStep").prop 'checked', conf.physics.adaptiveTimestep
