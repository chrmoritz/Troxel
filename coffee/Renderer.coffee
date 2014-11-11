# ToDo: Performance tests and optimisation
# ToDo: improve Alpha
# ToDo: support for type and specular map
# ToDo: reload with changing dimensions

class Renderer
  constructor: (io) ->
    @voxels = io.voxels
    @x = io.x
    @y = io.y
    @z = io.z
    @objects = []
    @theta = -90
    @width = $('#WebGlContainer').width()
    @height = window.innerHeight - 55
    @camera = new THREE.PerspectiveCamera 45, @width / @height, 1, 10000
    @camera.position.y = @y * 60
    @camera.position.x = @x * 25 + 100 * @x * Math.sin THREE.Math.degToRad @theta
    @camera.position.z = @z * 25 + 100 * @y * Math.cos THREE.Math.degToRad @theta
    @camera.lookAt new THREE.Vector3 @x * 25, @y * 25, @z * 25
    @scene = new THREE.Scene()
    # roll-over helpers
    rollOverGeo = new THREE.BoxGeometry 50, 50, 50
    rollOverMaterial = new THREE.MeshBasicMaterial color: 0xff0000, opacity: 0.5, transparent: true
    @rollOverMesh = new THREE.Mesh rollOverGeo, rollOverMaterial
    @scene.add @rollOverMesh
    # grid
    geometry = new THREE.Geometry()
    for z in [0..@z] by 1
      geometry.vertices.push new THREE.Vector3       0,       0,  50 * z # bottom grid
      geometry.vertices.push new THREE.Vector3 50 * @x,       0,  50 * z
      geometry.vertices.push new THREE.Vector3 50 * @x,       0,  50 * z # back grid
      geometry.vertices.push new THREE.Vector3 50 * @x, 50 * @y,  50 * z
    for x in [0..@x] by 1
      geometry.vertices.push new THREE.Vector3  50 * x,       0,       0 # bottom grid
      geometry.vertices.push new THREE.Vector3  50 * x,       0, 50 * @z
      geometry.vertices.push new THREE.Vector3  50 * x,       0,       0 # left grid
      geometry.vertices.push new THREE.Vector3  50 * x, 50 * @y,       0
    for y in [0..@y] by 1
      geometry.vertices.push new THREE.Vector3       0,  50 * y,       0 # left grid
      geometry.vertices.push new THREE.Vector3 50 * @x,  50 * y,       0
      geometry.vertices.push new THREE.Vector3 50 * @x,  50 * y,       0 # back grid
      geometry.vertices.push new THREE.Vector3 50 * @x,  50 * y, 50 * @z
    material = new THREE.LineBasicMaterial color: 0x000000, opacity: 0.2, transparent: true
    @grid = new THREE.Line geometry, material, THREE.LinePieces
    @scene.add @grid
    geometry = new THREE.PlaneBufferGeometry 50 * @x, 50 * @z
    geometry.applyMatrix new THREE.Matrix4().makeRotationX -Math.PI / 2
    @plane = new THREE.Mesh geometry
    @plane.position.x = 25 * @x
    @plane.position.z = 25 * @z
    @plane.visible = false
    @scene.add @plane
    @objects.push @plane
    # Raycaster
    @vector = new THREE.Vector3()
    @raycaster = new THREE.Raycaster()
    @isShiftDown = false
    # Load Model
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
          material = new THREE.MeshLambertMaterial color: new THREE.Color("rgb(#{@voxels[z][y][x].r},#{@voxels[z][y][x].g},#{@voxels[z][y][x].b})"), shading: THREE.FlatShading
          material.ambient = material.color
          if @voxels[z][y][x].a < 255
            material.transparent = true
            material.opacity = @voxels[z][y][x].a / 255
          voxel = new THREE.Mesh new THREE.BoxGeometry(50, 50, 50), material
          voxel.position.x = x * 50 + 25
          voxel.position.y = y * 50 + 25
          voxel.position.z = z * 50 + 25
          @scene.add voxel
          @objects.push voxel
    # Lights
    ambientLight = new THREE.AmbientLight 0x606060
    @scene.add ambientLight
    directionalLight = new THREE.DirectionalLight 0xffffff
    directionalLight.position.set(1, 0.75, 0.5).normalize()
    @scene.add directionalLight
    @renderer = new THREE.WebGLRenderer antialias: true
    @renderer.setClearColor 0x888888
    @renderer.setSize @width, @height
    $('#WebGlContainer').empty().append @renderer.domElement
    # Event handlers
    container = document.getElementById('WebGlContainer')
    container.addEventListener 'mousedown', (e) => @onDocumentMouseDown(e)
    container.addEventListener 'mousemove', (e) => @onDocumentMouseMove(e)
    document.addEventListener  'keydown',   (e) => @onDocumentKeyDown(e)
    document.addEventListener  'keyup',     (e) => @onDocumentKeyUp(e)
    window.addEventListener    'resize',    (e) => @onWindowResize(e)
    # Controls
    @controls = new THREE.OrbitControls @camera, container
    @controls.target = new THREE.Vector3 500, 500, 500
    @controls.addEventListener 'change', => @render()
    @controls.enabled = false
    @changeEditMode($('#modeEdit').parent().hasClass('active'))
    @animate()
    @render()

  reload: (io) ->
    @voxels = io.voxels
    @x = io.x
    @y = io.y
    @z = io.z
    @scene.remove o for o in @objects when o != @plane
    @objects = [@plane]
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
          material = new THREE.MeshLambertMaterial color: new THREE.Color("rgb(#{@voxels[z][y][x].r},#{@voxels[z][y][x].g},#{@voxels[z][y][x].b})"), shading: THREE.FlatShading
          material.ambient = material.color
          if @voxels[z][y][x].a < 255
            material.transparent = true
            material.opacity = @voxels[z][y][x].a / 255
          voxel = new THREE.Mesh new THREE.BoxGeometry(50, 50, 50), material
          voxel.position.x = x * 50 + 25
          voxel.position.y = y * 50 + 25
          voxel.position.z = z * 50 + 25
          @scene.add voxel
          @objects.push voxel
    @render()

  changeEditMode: (@editMode) ->
    if @editMode
      @grid.visible = true
      @rollOverMesh.visible = true
      @controls.enabled = false
    else
      @grid.visible = false
      @rollOverMesh.visible = false
      @controls.enabled = true
    @render()

  animate: ->
    requestAnimationFrame => @animate()
    @controls.update()

  render: (exportPng) ->
    @renderer.render @scene, @camera
    window.open @renderer.domElement.toDataURL('image/png'), 'Exported png' if exportPng

  onDocumentMouseMove: (e) ->
    return if !@editMode or $('#openModal').css('display') == 'block' or $('#exportModal').css('display') == 'block' or $('#saveModal').css('display') == 'block'
    e.preventDefault()
    @vector.set (e.clientX / @width) * 2 - 1, -((e.clientY - 50) / @height) * 2 + 1, 0.5
    @vector.unproject @camera
    @raycaster.ray.set @camera.position, @vector.sub(@camera.position).normalize()
    intersects = @raycaster.intersectObjects @objects
    if intersects.length > 0
      intersect = intersects[0]
      @rollOverMesh.position.copy(intersect.point).add(intersect.face.normal)
      @rollOverMesh.position.divideScalar(50).floor().multiplyScalar(50).addScalar(25)
    @render()

  onDocumentMouseDown: (e) ->
    return if !@editMode or $('#openModal').css('display') == 'block' or $('#exportModal').css('display') == 'block' or $('#saveModal').css('display') == 'block'
    e.preventDefault()
    @vector.set (e.clientX / @width) * 2 - 1, -((e.clientY - 50) / @height) * 2 + 1, 0.5
    @vector.unproject @camera
    @raycaster.ray.set @camera.position, @vector.sub(@camera.position).normalize()
    intersects = @raycaster.intersectObjects @objects
    if intersects.length > 0
      intersect = intersects[0]
      if @isShiftDown # delete cube
        if intersect.object != @plane
          x = (intersect.object.position.x - 25) / 50
          y = (intersect.object.position.y - 25) / 50
          z = (intersect.object.position.z - 25) / 50
          delete @voxels[z][y][x]
          delete @voxels[z][y] if @voxels[z][y].filter((e) -> return e != undefined).length == 0
          delete @voxels[z] if @voxels[z].filter((e) -> return e != undefined).length == 0
          @scene.remove intersect.object
          @objects.splice @objects.indexOf(intersect.object), 1
      else # create cube
        cubeMaterial = new THREE.MeshLambertMaterial color: new THREE.Color($('#addVoxColor').val()), shading: THREE.FlatShading
        cubeMaterial.ambient = cubeMaterial.color
        a = parseInt($('#addVoxAlpha').val())
        a = 255 if a == 272
        if a < 255
          cubeMaterial.transparent = true
          cubeMaterial.opacity = a / 255
        voxel = new THREE.Mesh new THREE.BoxGeometry(50, 50, 50), cubeMaterial
        voxel.position.copy(intersect.point).add(intersect.face.normal)
        voxel.position.divideScalar(50).floor().multiplyScalar(50).addScalar(25)
        x = (voxel.position.x - 25) / 50
        y = (voxel.position.y - 25) / 50
        z = (voxel.position.z - 25) / 50
        return unless 0 <= x < @x and 0 <= y < @y and 0 <= z < @z
        @voxels[z] = [] unless @voxels[z]?
        @voxels[z][y] = [] unless @voxels[z][y]?
        @voxels[z][y][x] =
          r: parseInt($('#addVoxColor').val().substring(1, 3),16)
          g: parseInt($('#addVoxColor').val().substring(3, 5),16)
          b: parseInt($('#addVoxColor').val().substring(5, 7),16)
          a: a, t: parseInt($('#addVoxType').val()), s: parseInt($('#addVoxSpecular').val())
        @scene.add voxel
        @objects.push voxel
      @render()

  onDocumentKeyDown: (e) ->
    switch e.keyCode
      when 16 then @isShiftDown = true
      #when 17 then @isCtrlDown = true

  onDocumentKeyUp: (e) ->
    switch e.keyCode
      when 16 then @isShiftDown = false
      #when 17 then @isCtrlDown = false

  onWindowResize: ->
    @width = $('#WebGlContainer').width()
    @height = window.innerHeight - 55
    @camera.aspect = @width / @height
    @camera.updateProjectionMatrix()
    @renderer.setSize @width, @height

if typeof module == 'object' then module.exports = Renderer else window.Renderer = Renderer
