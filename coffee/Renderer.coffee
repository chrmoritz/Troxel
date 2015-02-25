'use strict'
class Renderer
  constructor: (io, @embedded = false, @domContainer = $('#WebGlContainer'), antialias = true) ->
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
    if @embedded # we are most likely autorotating => zoom that is always fit the camera
      a = Math.max @x, @y, @z
      @camera.position.x = -80 * a
      @camera.position.y =  50 * a
      @camera.position.z =  25 * a
    else
      @camera.position.x = -50 * @y - 20 * @x - 10 * @z
      @camera.position.y =  50 * @y
      @camera.position.z =  25 * @x
    @controls = new THREE.OrbitControls @camera, @domContainer[0]
    @controls.target = new THREE.Vector3 @z * 25, @y * 25, @x * 25
    @controls.noKeys = true
    @controls.addEventListener 'change', => @render()
    # Event handlers
    document.addEventListener 'keydown', (e) => @onDocumentKeyDown(e)
    window.addEventListener    'resize', (e) => @onWindowResize(e)
    @animate() if @embedded

  getMaterial: (color, a, t, s) ->
    material = new THREE.MeshPhongMaterial color: color, ambient: color
    if t in [3, 4] # glowing solid, glowing glass
      material.emissive = material.color.multiplyScalar 0.5
    if s == 1 # metal
      material.specular = material.color.multiplyScalar 0.5
    if t in [1, 2, 4] # glass, tiled glass or glowing glass
      material.transparent = true
      material.opacity = a / 255
    return material

  reload: (@voxels, @x, @y, @z) ->
    matrix = new THREE.Matrix4() # dummy matrix
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
    for z in [0...@z] by 1 when @voxels[z]?
      for y in [0...@y] by 1 when @voxels[z]?[y]?
        for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
          color = new THREE.Color("rgb(#{@voxels[z][y][x].r},#{@voxels[z][y][x].g},#{@voxels[z][y][x].b})")
          matIndex = null
          if reverseMaterialIndex[color.getHex()]?[@voxels[z][y][x].a + 256 * @voxels[z][y][x].t + 2048 * @voxels[z][y][x].s]?
            matIndex = reverseMaterialIndex[color.getHex()][@voxels[z][y][x].a + 256 * @voxels[z][y][x].t + 2048 * @voxels[z][y][x].s]
          else
            matIndex = materials.length
            materials.push @getMaterial color, @voxels[z][y][x].a, @voxels[z][y][x].t, @voxels[z][y][x].s
            reverseMaterialIndex[color.getHex()] = [] if !reverseMaterialIndex[color.getHex()]?
            reverseMaterialIndex[color.getHex()][@voxels[z][y][x].a + 256 * @voxels[z][y][x].t + 2048 * @voxels[z][y][x].s] = matIndex
          matrix.makeTranslation z * 50 + 25, y * 50 + 25, x * 50 + 25 # position
          geometry.merge px, matrix, matIndex if !@voxels[z+1]?[y]?[x]? or (@voxels[z+1][y][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # back
          geometry.merge nx, matrix, matIndex if !@voxels[z-1]?[y]?[x]? or (@voxels[z-1][y][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # front
          geometry.merge py, matrix, matIndex if !@voxels[z]?[y+1]?[x]? or (@voxels[z][y+1][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # top
          geometry.merge ny, matrix, matIndex if !@voxels[z]?[y-1]?[x]? or (@voxels[z][y-1][x].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # bottom
          geometry.merge pz, matrix, matIndex if !@voxels[z]?[y]?[x+1]? or (@voxels[z][y][x+1].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # right
          geometry.merge nz, matrix, matIndex if !@voxels[z]?[y]?[x-1]? or (@voxels[z][y][x-1].t in [1, 2, 4] and @voxels[z][y][x].t not in [1, 2, 4]) # left
    @mesh = new THREE.Mesh geometry, new THREE.MeshFaceMaterial materials
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
