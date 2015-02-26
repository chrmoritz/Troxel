'use strict'
class Renderer
  constructor: (io, @embedded = false, @domContainer = $('#WebGlContainer'), @renderMode = 0, @renderWireframes = 0, antialias = true) ->
    @width = @domContainer.width()
    @height = @domContainer.height() - (if @embedded then 0 else 5)
    @scene = new THREE.Scene()
    @reload io.voxels, io.x, io.y, io.z, false, true
    # Lights
    @ambientLight = new THREE.AmbientLight 0x606060
    @scene.add @ambientLight
    @directionalLight = new THREE.DirectionalLight 0xffffff, 0.3
    @directionalLight.position.set(-0.5, -0.5, 1).normalize()
    @scene.add @directionalLight
    @spotLight = new THREE.SpotLight 0xffffff, 0.7, 100000
    @spotLightTarget = new THREE.Object3D()
    @spotLightTarget.position.x = @z * 25
    @spotLightTarget.position.y = @y * 25
    @spotLightTarget.position.z = @x * 25
    @scene.add @spotLightTarget
    @spotLight.target = @spotLightTarget
    @scene.add @spotLight
    @renderer = new THREE.WebGLRenderer antialias: antialias
    @renderer.setClearColor 0x888888
    @renderer.setSize @width, @height
    @domContainer.empty().append @renderer.domElement
    # Controls and Camera
    @camera = new THREE.PerspectiveCamera 45, @width / @height, 1, 100000
    miny = 0
    if @embedded
      miny = @y
      for z in [0...@z] by 1 when @voxels[z]? # ignore empty y (height) space on deco models
        (miny = Math.min miny, y; break) for y in [0...@y] by 1 when @voxels[z]?[y]?
      a = Math.max @x, @y - miny, @z # we are most likely autorotating => zoom that is always fit the camera
      @camera.position.x = -80 * a
      @camera.position.y =  50 * (a + miny)
      @camera.position.z =  25 * a
    else
      @camera.position.x = -50 * @y - 20 * @x - 10 * @z
      @camera.position.y =  50 * @y
      @camera.position.z =  25 * @x
    @controls = new THREE.OrbitControls @camera, @domContainer[0]
    @controls.target = new THREE.Vector3 @z * 25, (@y + miny) * 25, @x * 25
    @controls.noKeys = true
    @controls.addEventListener 'change', => @render()
    # Event handlers
    document.addEventListener 'keydown', (e) => @onDocumentKeyDown(e)
    window.addEventListener    'resize', (e) => @onWindowResize(e)
    @animate() if @embedded

  getMaterial: (color, a, t, s) ->
    switch @renderMode
      when 0, 1 then break
      when 2 then color = {250:0xff00ff, 16:0x101010, 48:0x303030, 80:0x505050, 12:0x707070, 144:0x909090, 176:0xb0b0b0, 208:0xd0d0d0, 240:0xf0f0f0, 255:0xffffff}[a]
      when 3 then color = [0xffffff, 0x808080, 0x404040, 0xff0000, 0xffff00, null, null, 0xff00ff][t]
      when 4 then color = [0x800000, 0x008000, 0x000080, 0x808000, null, null, null, 0xff00ff][s]
    material = new THREE.MeshPhongMaterial color: color, ambient: color
    if @renderMode == 0
      if t in [3, 4] # glowing solid, glowing glass
        material.emissive = material.color.multiplyScalar 0.5
      if s == 1 # metal
        material.specular = material.color.multiplyScalar 0.5
      if t in [1, 2, 4] # glass, tiled glass or glowing glass
        material.transparent = true
        material.opacity = a / 255
    return material

  reload: (@voxels, @x, @y, @z, resize = false, init = false) ->
    if resize
      @spotLightTarget.position.x = @z * 25
      @spotLightTarget.position.y = @y * 25
      @spotLightTarget.position.z = @x * 25
      @spotLight.target = @spotLightTarget
      @camera.position.x = -50 * @y - 20 * @x - 10 * @z
      @camera.position.y = @y * 50
      @camera.position.z = @x * 25
      @controls.target = new THREE.Vector3 @z * 25, @y * 25, @x * 25
    unless init
      @scene.remove @mesh
      @scene.remove @wireframe if @wireframe?
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
          color.setRGB @voxels[z][y][x].r / 255, @voxels[z][y][x].g / 255, @voxels[z][y][x].b / 255
          if reverseMaterialIndex[color.getHex()]?[@voxels[z][y][x].a + 256 * @voxels[z][y][x].t + 2048 * @voxels[z][y][x].s]?
            matIndex = reverseMaterialIndex[color.getHex()][@voxels[z][y][x].a + 256 * @voxels[z][y][x].t + 2048 * @voxels[z][y][x].s]
          else
            matIndex = materials.length
            reverseMaterialIndex[color.getHex()] = [] if !reverseMaterialIndex[color.getHex()]?
            reverseMaterialIndex[color.getHex()][@voxels[z][y][x].a + 256 * @voxels[z][y][x].t + 2048 * @voxels[z][y][x].s] = matIndex
            materials.push @getMaterial color, @voxels[z][y][x].a, @voxels[z][y][x].t, @voxels[z][y][x].s
          matrix.makeTranslation z * 50 + 25, y * 50 + 25, x * 50 + 25 # position
          geometry.merge px, matrix, matIndex if !@voxels[z+1]?[y]?[x]? or (@voxels[z+1][y][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # back
          geometry.merge nx, matrix, matIndex if !@voxels[z-1]?[y]?[x]? or (@voxels[z-1][y][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # front
          geometry.merge py, matrix, matIndex if !@voxels[z]?[y+1]?[x]? or (@voxels[z][y+1][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # top
          geometry.merge ny, matrix, matIndex if !@voxels[z]?[y-1]?[x]? or (@voxels[z][y-1][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # bottom
          geometry.merge pz, matrix, matIndex if !@voxels[z]?[y]?[x+1]? or (@voxels[z][y][x+1].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # right
          geometry.merge nz, matrix, matIndex if !@voxels[z]?[y]?[x-1]? or (@voxels[z][y][x-1].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # left
          if @renderWireframes > 0
            wcolor = switch @renderWireframes # can't use dummy here because we are pushing to an array with reference
              when 2 then new THREE.Color @voxels[z][y][x].r / 255, @voxels[z][y][x].g / 255, @voxels[z][y][x].b / 255
              when 3 then new THREE.Color {250: 0xff00ff,  16: 0x101010,  48: 0x303030,  80: 0x505050, 12: 0x707070, 144: 0x909090
                                          ,176: 0xb0b0b0, 208: 0xd0d0d0, 240: 0xf0f0f0, 255: 0xffffff}[@voxels[z][y][x].a]
              when 4 then new THREE.Color [0xffffff, 0x808080, 0x404040, 0xff0000, 0xffff00, null, null, 0xff00ff][@voxels[z][y][x].t]
              when 5 then new THREE.Color [0x800000, 0x008000, 0x000080, 0x808000, null, null, null, 0xff00ff][@voxels[z][y][x].s]
              else new THREE.Color 0x333333 # grey
            if !@voxels[z+1]?[y]?[x]?
              wireGeo.vertices.push new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x     ), new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ), new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z-1]?[y]?[x]?
              wireGeo.vertices.push new THREE.Vector3(50 * z, 50 * y     , 50 * x     ), new THREE.Vector3( 50 * z, 50 * y     , 50 * x + 50),
                                    new THREE.Vector3(50 * z, 50 * y     , 50 * x + 50), new THREE.Vector3( 50 * z, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z, 50 * y + 50, 50 * x + 50), new THREE.Vector3( 50 * z, 50 * y + 50, 50 * x     ),
                                    new THREE.Vector3(50 * z, 50 * y + 50, 50 * x     ), new THREE.Vector3( 50 * z, 50 * y     , 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y+1]?[x]?
              wireGeo.vertices.push new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y-1]?[x]?
              wireGeo.vertices.push new THREE.Vector3(50 * z     , 50 * y, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y, 50 * x + 50),
                                    new THREE.Vector3(50 * z     , 50 * y, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y, 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y, 50 * x     ),
                                    new THREE.Vector3(50 * z + 50, 50 * y, 50 * x     ), new THREE.Vector3(50 * z     , 50 * y, 50 * x     )
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y]?[x+1]?
              wireGeo.vertices.push new THREE.Vector3(50 * z     , 50 * y     , 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y     , 50 * x + 50), new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z + 50, 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50),
                                    new THREE.Vector3(50 * z     , 50 * y + 50, 50 * x + 50), new THREE.Vector3(50 * z     , 50 * y     , 50 * x + 50)
              wireGeo.colors.push wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor, wcolor
            if !@voxels[z]?[y]?[x-1]?
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

  animate: ->
    requestAnimationFrame => @animate()
    @controls.update()
    @stats.update() unless @embedded

  render: (exportPng) ->
    @spotLight.position.copy @camera.position
    @renderer.render @scene, @camera
    window.open @renderer.domElement.toDataURL('image/png'), 'Exported png' if exportPng

  onDocumentKeyDown: (e) ->
    switch e.keyCode
      when 87 then @controls.rotateUp   -0.05 # W
      when 65 then @controls.rotateLeft -0.05 # A
      when 83 then @controls.rotateUp    0.05 # S
      when 68 then @controls.rotateLeft  0.05 # D
      when 81 then @controls.dollyIn()        # Q
      when 69 then @controls.dollyOut()       # E
      when 37 then @controls.pan  7.0,  0     # left
      when 38 then @controls.pan  0  ,  7.0   # up
      when 39 then @controls.pan -7.0,  0     # right
      when 40 then @controls.pan  0  , -7.0   # bottom
      else true

  onWindowResize: ->
    @width = @domContainer.width()
    @height = @domContainer.height() - (if @embedded then 0 else 5)
    @camera.aspect = @width / @height
    @camera.updateProjectionMatrix()
    @renderer.setSize @width, @height
    @render()

if typeof module == 'object' then module.exports = Renderer else window.Renderer = Renderer
