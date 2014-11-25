window.Troxel =
  webgl: -> try
    canvas = document.createElement 'canvas'
    !!(window.WebGLRenderingContext && (canvas.getContext 'webgl' || canvas.getContext 'experimental-webgl'))
  catch
    false
  renderBlueprint: (blueprintId, domElement, options) ->
    $.ajax dataType: 'jsonp', url: 'https://chrmoritz.github.io/Troxel/static/Trove.jsonp', jsonpCallback: 'callback', success: (data) ->
      model = data[blueprintId]
      return Troxel.renderBase64(model, domElement, options, blueprintId) if model?
      console.warn "blueprintId #{blueprintId} not found"
  renderBase64: (base64, domElement, options = {}, blueprintId) ->
    return console.warn "WebGL is not supported by your browser" unless Troxel.webgl()
    domElement = $(domElement).empty().css('position', 'relative')
    io = new Base64IO base64
    renderer = new Renderer io, true, domElement
    # Options
    renderer.renderer.setClearColor options.rendererClearColor if options.rendererClearColor?
    renderer.ambientLight.color = new THREE.Color options.ambientLightColor if options.ambientLightColor?
    renderer.directionalLight.color = new THREE.Color options.directionalLightColor if options.directionalLightColor?
    renderer.directionalLight.intensity = options.directionalLightIntensity if options.directionalLightIntensity?
    if options.directionalLightVector? && options.directionalLightVector.x? && options.directionalLightVector.y? && options.directionalLightVector.z?
      renderer.directionalLight.position.set(options.directionalLightVector.x, options.directionalLightVector.y, options.directionalLightVector.z).normalize()
    if !options.autoRotate? || options.autoRotate
      renderer.controls.autoRotate = true
      renderer.controls.autoRotateSpeed = options.autoRotateSpeed if options.autoRotateSpeed?
    if !options.showInfoLabel? || options.showInfoLabel
      link = if blueprintId? then '#b=' + blueprintId else '#m=' + base64
      info = $("<div><a href='http://chrmoritz.github.io/Troxel/#{link}' target='_blank' class='troxelLink'>Open this model in Troxel</a></div>")
      domElement.append info.css position: 'absolute', bottom: '0px', width: '100%', textAlign: 'center'
