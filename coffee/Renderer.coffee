'use strict'
THREE = require('three')
require('three/examples/js/shaders/SSAOShader')
require('three/examples/js/shaders/FXAAShader')
require('three/examples/js/shaders/CopyShader')
require('three/examples/js/postprocessing/ShaderPass')
require('three/examples/js/postprocessing/RenderPass')
require('three/examples/js/postprocessing/MaskPass')
require('three/examples/js/postprocessing/EffectComposer')
TroxelControls = require('./Controls.coffee!')
$ = require('jquery')

class Renderer
  constructor: (io, @embedded = false, @domContainer = $('#WebGlContainer'), @renderMode = 0, @renderWireframes = 0, antialias = true, @ssao = false, renderControls = true) ->
    @width = @domContainer.width()
    @height = @domContainer.height()
    @scene = new THREE.Scene()
    # Camera and Controls
    @camera = new THREE.PerspectiveCamera 45, @width / @height, 1, 100000
    @controls = new TroxelControls @camera, @domContainer[0]
    @controls.mode = renderControls
    @controls.addEventListener 'change', => @render()
    @reload io.voxels, io.x, io.y, io.z, false, true
    # Lights
    @ambientLight = new THREE.AmbientLight 0x606060
    @scene.add @ambientLight
    @directionalLight = new THREE.DirectionalLight 0xffffff, 0.3
    @directionalLight.position.set(-0.5, -0.5, 1).normalize()
    @scene.add @directionalLight
    @pointLight = new THREE.PointLight 0xffffff, 0.6, 100000
    @camera.add @pointLight
    @scene.add @camera
    # Renderer
    @renderer = new THREE.WebGLRenderer antialias: antialias
    @renderer.setClearColor 0x888888
    @renderer.setPixelRatio window.devicePixelRatio
    @renderer.setSize @width, @height
    @domContainer.empty().append @renderer.domElement
    window.test = @
    # postprocessing effects
    if @ssao
      @composer = new THREE.EffectComposer @renderer
      @composer.addPass new THREE.RenderPass @scene, @camera
      @ssaoPass = new THREE.ShaderPass THREE.SSAOShader
      @depthRenderTarget = new THREE.WebGLRenderTarget @width, @height, {minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter}
      @ssaoPass.uniforms['tDepth'].value = @depthRenderTarget
      @ssaoPass.uniforms['size'].value.set @width, @height
      @ssaoPass.uniforms['cameraNear'].value = @camera.near
      @ssaoPass.uniforms['cameraFar'].value = @camera.far
      @ssaoPass.uniforms['onlyAO'].value = false
      @ssaoPass.uniforms['aoClamp'].value = 0.5
      @ssaoPass.uniforms['lumInfluence'].value = 0.25
      @composer.addPass @ssaoPass
      @fxaaPass = new THREE.ShaderPass THREE.FXAAShader
      @fxaaPass.uniforms['resolution'].value.set 1 / @width, 1 / @height
      @fxaaPass.renderToScreen = true
      @composer.addPass @fxaaPass
      ds = THREE.ShaderLib['depthRGBA']
      du = THREE.UniformsUtils.clone ds.uniforms
      @depthMaterial = new THREE.ShaderMaterial {fragmentShader: ds.fragmentShader, vertexShader: ds.vertexShader, uniforms: du, blending: THREE.NoBlending}
    # Event handlers
    window.addEventListener 'resize', (e) => @onWindowResize(e)
    @animate() if @embedded

  getMaterial: (color, a, t, s) ->
    switch @renderMode
      when 0, 1 then break
      when 2 then color = {250:0xff00ff, 16:0x101010, 48:0x303030, 80:0x505050, 12:0x707070, 144:0x909090, 176:0xb0b0b0, 208:0xd0d0d0, 240:0xf0f0f0, 255:0xffffff}[a]
      when 3 then color = [0xffffff, 0x808080, 0x404040, 0xff0000, 0xffff00, null, null, 0xff00ff][t]
      when 4 then color = [0x800000, 0x008000, 0x000080, 0x808000, 0x800080, null, null, 0xff00ff][s]
    material = new THREE.MeshPhongMaterial color: color, ambient: color
    if @renderMode == 0
      if t in [3, 4] # glowing solid, glowing glass
        material.emissive = material.color.multiplyScalar 0.5
      if s == 1 # metal
        material.specular = material.color.multiplyScalar 0.5
      if t in [1, 2, 4] # glass, tiled glass or glowing glass
        material.transparent = true
        material.opacity = a / 255
    else
      material.shininess = 0.1
    return material

  reload: (@voxels, @x, @y, @z, resize = false, init = false) ->
    if resize or init
      if @embedded
        a = Math.max @x, @z # we are most likely autorotating => zoom that is always fit the camera
        @camera.position.x = 85 * a + 65 * @y
        @camera.position.y = 50 * @y
        @camera.position.z = 25 * a
      else
        @camera.position.x = 65 * @y + 35 * @x + 55 * @z
        @camera.position.y = 50 * @y
        @camera.position.z = 25 * @x
      @controls.target = new THREE.Vector3 @z * 25, @y * 25, @x * 25
    unless init
      @scene.remove @mesh
      @mesh.geometry.dispose()
      if @wireframe?
        @scene.remove @wireframe
        @wireframe.geometry.dispose()
    matrix = new THREE.Matrix4() # dummy matrix
    color = new THREE.Color()    # dummy color
    px = new THREE.PlaneGeometry 50, 50 # back
    px.applyMatrix matrix.makeRotationY Math.PI / 2
    px.applyMatrix matrix.makeTranslation 25, 0, 0
    nx = new THREE.PlaneGeometry 50, 50 # front
    nx.applyMatrix matrix.makeRotationY -Math.PI / 2
    nx.applyMatrix matrix.makeTranslation -25, 0, 0
    py = new THREE.PlaneGeometry 50, 50 # top
    py.applyMatrix matrix.makeRotationX -Math.PI / 2
    py.applyMatrix matrix.makeTranslation 0, 25, 0
    ny = new THREE.PlaneGeometry 50, 50 # bottom
    ny.applyMatrix matrix.makeRotationX Math.PI / 2
    ny.applyMatrix matrix.makeTranslation 0, -25, 0
    pz = new THREE.PlaneGeometry 50, 50 # right
    pz.applyMatrix matrix.makeTranslation 0, 0, 25
    nz = new THREE.PlaneGeometry 50, 50 # left
    nz.applyMatrix matrix.makeRotationY Math.PI
    nz.applyMatrix matrix.makeTranslation 0, 0, -25
    geometry = new THREE.Geometry()
    materials = []
    reverseMaterialIndex = []
    # Wireframe
    @wireframe = null
    wireGeo = new THREE.Geometry() if @renderWireframes > 0
    for z in [0...@z] by 1 when @voxels[z]?
      for y in [0...@y] by 1 when @voxels[z]?[y]?
        for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
          vox = @voxels[z][y][x]
          color.setRGB vox.r / 255, vox.g / 255, vox.b / 255
          hex = color.getHex()
          mat = vox.a + 256 * vox.t + 2048 * vox.s
          if reverseMaterialIndex[hex]?[mat]?
            matIndex = reverseMaterialIndex[hex][mat]
          else
            matIndex = materials.length
            reverseMaterialIndex[hex] = [] if !reverseMaterialIndex[hex]?
            reverseMaterialIndex[hex][mat] = matIndex
            materials.push @getMaterial color, vox.a, vox.t, vox.s
          matrix.makeTranslation z * 50 + 25, y * 50 + 25, x * 50 + 25 # position
          geometry.merge px, matrix, matIndex if !@voxels[z+1]?[y]?[x]? or (@voxels[z+1][y][x].t in [1, 2, 4] and vox.t not in [1, 2, 4]) # back
          geometry.merge nx, matrix, matIndex if !@voxels[z-1]?[y]?[x]? or (@voxels[z-1][y][x].t in [1, 2, 4] and vox.t not in [1, 2, 4]) # front
          geometry.merge py, matrix, matIndex if !@voxels[z]?[y+1]?[x]? or (@voxels[z][y+1][x].t in [1, 2, 4] and vox.t not in [1, 2, 4]) # top
          geometry.merge ny, matrix, matIndex if !@voxels[z]?[y-1]?[x]? or (@voxels[z][y-1][x].t in [1, 2, 4] and vox.t not in [1, 2, 4]) # bottom
          geometry.merge pz, matrix, matIndex if !@voxels[z]?[y]?[x+1]? or (@voxels[z][y][x+1].t in [1, 2, 4] and vox.t not in [1, 2, 4]) # right
          geometry.merge nz, matrix, matIndex if !@voxels[z]?[y]?[x-1]? or (@voxels[z][y][x-1].t in [1, 2, 4] and vox.t not in [1, 2, 4]) # left
          if @renderWireframes > 0
            wcolor = switch @renderWireframes # can't use dummy here because we are pushing to an array with reference
              when 2 then new THREE.Color vox.r / 255, vox.g / 255, vox.b / 255
              when 3 then new THREE.Color {250: 0xff00ff,  16: 0x101010,  48: 0x303030,  80: 0x505050, 12: 0x707070, 144: 0x909090
                                         , 176: 0xb0b0b0, 208: 0xd0d0d0, 240: 0xf0f0f0, 255: 0xffffff}[vox.a]
              when 4 then new THREE.Color [0xffffff, 0x808080, 0x404040, 0xff0000, 0xffff00, null, null, 0xff00ff][vox.t]
              when 5 then new THREE.Color [0x800000, 0x008000, 0x000080, 0x808000, 0x800080, null, null, 0xff00ff][vox.s]
              when 6
                if vox.linter?
                  new THREE.Color vox.linter
                else
                  false
              else new THREE.Color 0x333333 # grey
            if !@voxels[z+1]?[y]?[x]? and wcolor
              wireGeo.vertices.push new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x     ), new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ), new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z-1]?[y]?[x]? and wcolor
              wireGeo.vertices.push new THREE.Vector3(50 * z, 50 * y     , 50 * x     ), new THREE.Vector3( 50 * z, 50 * y     , 50 * x + 50),
                                    new THREE.Vector3(50 * z, 50 * y     , 50 * x + 50), new THREE.Vector3( 50 * z, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z, 50 * y + 50, 50 * x + 50), new THREE.Vector3( 50 * z, 50 * y + 50, 50 * x     ),
                                    new THREE.Vector3(50 * z, 50 * y + 50, 50 * x     ), new THREE.Vector3( 50 * z, 50 * y     , 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y+1]?[x]? and wcolor
              wireGeo.vertices.push new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y-1]?[x]? and wcolor
              wireGeo.vertices.push new THREE.Vector3(50 * z     , 50 * y, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y, 50 * x + 50),
                                    new THREE.Vector3(50 * z     , 50 * y, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y, 50 * x     ),
                                    new THREE.Vector3(50 * z + 50, 50 * y, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y, 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y]?[x+1]? and wcolor
              wireGeo.vertices.push new THREE.Vector3(50 * z     , 50 * y     , 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z     , 50 * y     , 50 * x + 50)
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y]?[x-1]? and wcolor
              wireGeo.vertices.push new THREE.Vector3(50 * z     , 50 * y     , 50 * x), new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x),
                                    new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x), new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x),
                                    new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x), new THREE.Vector3(50 * z     , 50 * y     , 50 * x)
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
    @mesh = new THREE.Mesh geometry, new THREE.MeshFaceMaterial materials
    if @renderWireframes > 0
      linemat = new THREE.LineBasicMaterial vertexColors: THREE.VertexColors, linewidth: 2
      @wireframe = new THREE.Line wireGeo, linemat, THREE.LinePieces
      @scene.add @wireframe
    @scene.add @mesh
    @controls.needsRender = true unless init

  animate: ->
    requestAnimationFrame => @animate()
    @stats.begin() unless @embedded
    @controls.update @stats

  render: (exportPng) ->
    if @ssao
      @scene.overrideMaterial = @depthMaterial
      @renderer.render @scene, @camera, @depthRenderTarget, true
      @scene.overrideMaterial = null
      @composer.render()
    else
      @renderer.render @scene, @camera
    @stats.end() unless @embedded
    window.open @renderer.domElement.toDataURL(), 'Exported png' if exportPng

  onWindowResize: ->
    @width = @domContainer.width()
    @height = @domContainer.height()
    @camera.aspect = @width / @height
    @camera.updateProjectionMatrix()
    @renderer.setSize @width, @height
    if @ssao
      @ssaoPass.uniforms['size'].value.set @width, @height
      @fxaaPass.uniforms['resolution'].value.set 1 / @width, 1 / @height
      @composer.setSize @width, @height
    @controls.needsRender = true

module.exports = Renderer
