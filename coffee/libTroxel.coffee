'use strict'
window.Troxel =
  webgl: -> try
    canvas = document.createElement 'canvas'
    !!(window.WebGLRenderingContext && (canvas.getContext 'webgl' || canvas.getContext 'experimental-webgl'))
  catch
    false
  renderBlueprint: (blueprintId, domElement, options, cb) ->
    unless Troxel.webgl()
      console.warn "WebGL is not supported by your browser"
      return cb new Error "WebGl is not supported" if typeof cb == 'function'
    $.ajax dataType: 'jsonp', url: 'https://chrmoritz.github.io/Troxel/static/Trove.jsonp', jsonpCallback: 'callback', cache: true, success: (data) ->
      model = data[blueprintId]
      result = {error: new Error "blueprintId #{blueprintId} not found"}
      if model?
        result = Troxel.renderBase64(model, domElement, options, blueprintId)
      else
        console.warn "blueprintId #{blueprintId} not found"
      cb result.error, result.options if typeof cb == 'function'
  renderBase64: (base64, domElement, options = {}, blueprintId) ->
    unless Troxel.webgl()
      console.warn "WebGL is not supported by your browser"
      return {error: new Error "WebGL is not supported by your browser"}
    domElement = $(domElement).empty().css('position', 'relative')
    io = null
    try
      io = new Base64IO base64
    catch
      console.warn "passed String is not a valid base64 encoded voxel model"
      return {error: new Error "passed String is not a valid base64 encoded voxel model"}
    renderer = new Renderer io, true, domElement, options.renderMode || 0, options.renderWireframes || 0, options.rendererAntialias || true
    # Options
    renderer.renderer.setClearColor options.rendererClearColor if options.rendererClearColor?
    renderer.ambientLight.color = new THREE.Color options.ambientLightColor if options.ambientLightColor?
    renderer.directionalLight.color = new THREE.Color options.directionalLightColor if options.directionalLightColor?
    renderer.directionalLight.intensity = options.directionalLightIntensity if options.directionalLightIntensity?
    if options.directionalLightVector? && options.directionalLightVector.x? && options.directionalLightVector.y? && options.directionalLightVector.z?
      renderer.directionalLight.position.set(options.directionalLightVector.x, options.directionalLightVector.y, options.directionalLightVector.z).normalize()
    renderer.spotLight.color = new THREE.Color options.spotLightColor if options.spotLightColor?
    renderer.spotLight.intensity = options.spotLightIntensity if options.spotLightIntensity?
    if !options.autoRotate? || options.autoRotate
      renderer.controls.autoRotate = true
      renderer.controls.autoRotateSpeed = options.autoRotateSpeed or -4.0
    renderer.controls.noZoom = true if options.noZoom? and options.noZoom
    renderer.controls.noPan = true if options.noPan? and options.noPan
    renderer.controls.noRotate = true if options.noRotate? and options.noRotate
    if !options.showInfoLabel? || options.showInfoLabel
      link = if blueprintId? then '#b=' + blueprintId else '#m=' + base64
      info = $("<div><a href='http://chrmoritz.github.io/Troxel/#{link}' target='_blank' class='troxelLink'>Open this model in Troxel</a></div>")
      domElement.append info.css position: 'absolute', bottom: '0px', width: '100%', textAlign: 'center'
    resultOptions = {}
    _resultOptions = {rendererClearColor: 0x888888, ambientLightColor: 0x606060, directionalLightColor: 0xffffff, directionalLightIntensity: 0.3
                      ,directionalLightVector: {x: -0.5, y: -0.5, z: 1}, spotLightColor: 0xffffff, spotLightIntensity: 0.7
                      ,autoRotate: true, autoRotateSpeed: -4.0, noZoom: false, noPan: false, noRotate: false}
    Object.defineProperties resultOptions, {
      "rendererClearColor":
        set: (s) -> _resultOptions.rendererClearColor = s; renderer.renderer.setClearColor s; renderer.render()
        get: -> _resultOptions.rendererClearColor
      "ambientLightColor":
        set: (s) -> _resultOptions.ambientLightColor = s; renderer.ambientLight.color = new THREE.Color s; renderer.render()
        get: -> _resultOptions.ambientLightColor
      "directionalLightColor":
        set: (s) -> _resultOptions.directionalLightColor = s; renderer.directionalLight.color = new THREE.Color s; renderer.render()
        get: -> _resultOptions.directionalLightColor
      "directionalLightIntensity":
        set: (s) -> _resultOptions.directionalLightIntensity = s; renderer.directionalLight.intensity = s; renderer.render()
        get: -> _resultOptions.directionalLightIntensity
      "directionalLightVector":
        set: (s) -> (_resultOptions.directionalLightVector = s; renderer.directionalLight.position.set(s.x, s.y, s.z).normalize(); renderer.render()) if s.x? and s.y? and s.z?
        get: -> _resultOptions.directionalLightVector
      "spotLightColor":
        set: (s) -> _resultOptions.spotLightColor = s; renderer.spotLight.color = new THREE.Color s; renderer.render()
        get: -> _resultOptions.spotLightColor
      "spotLightIntensity":
        set: (s) -> _resultOptions.spotLightIntensity = s; renderer.spotLight.intensity = s; renderer.render()
        get: -> _resultOptions.spotLightIntensity
      "autoRotate":
        set: (s) -> _resultOptions.autoRotate = s; renderer.controls.autoRotate = s; renderer.render()
        get: -> _resultOptions.autoRotate
      "autoRotateSpeed":
        set: (s) -> (_resultOptions.autoRotateSpeed = s; renderer.controls.autoRotateSpeed = s; renderer.render()) if renderer.controls.autoRotate
        get: -> _resultOptions.autoRotateSpeed
      "noZoom":
        set: (s) -> _resultOptions.noZoom = s; renderer.controls.noZoom = s; renderer.render()
        get: -> _resultOptions.noZoom
      "noPan":
        set: (s) -> _resultOptions.noPan = s; renderer.controls.noPan = s; renderer.render()
        get: -> _resultOptions.noPan
      "noRotate":
        set: (s) -> _resultOptions.noRotate = s; renderer.controls.noRotate = s; renderer.render()
        get: -> _resultOptions.noRotate
    }
    return {error: null, options: resultOptions}

$ ->
  $('div[data-troxel-blueprint]').each -> Troxel.renderBlueprint $(@).data('troxel-blueprint'), @, $(@).data('troxel-options')
  $('div[data-troxel-base64]').each -> Troxel.renderBase64 $(@).data('troxel-base64'), @, $(@).data('troxel-options')
