class Renderer
  constructor: (io, @embedded = false, @domContainer = $('#WebGlContainer')) ->
    @voxels = io.voxels
    @x = io.x
    @y = io.y
    @z = io.z
    @objects = []
    @width = @domContainer.width()
    @height = @domContainer.height() - 5
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
    # Planes
    @planes = []
    geometry = new THREE.PlaneBufferGeometry 50 * @z, 50 * @y
    geometry.applyMatrix new THREE.Matrix4().makeRotationY -Math.PI / 2
    plane = new THREE.Mesh geometry
    plane.position.x = 50 * @x
    plane.position.y = 25 * @y
    plane.position.z = 25 * @z
    plane.visible = false
    @scene.add plane
    @objects.push plane
    @planes.push plane
    geometry = new THREE.PlaneBufferGeometry 50 * @x, 50 * @z
    geometry.applyMatrix new THREE.Matrix4().makeRotationX -Math.PI / 2
    plane = new THREE.Mesh geometry
    plane.position.x = 25 * @x
    plane.position.z = 25 * @z
    plane.visible = false
    @scene.add plane
    @objects.push plane
    @planes.push plane
    geometry = new THREE.PlaneBufferGeometry 50 * @y, 50 * @x
    geometry.applyMatrix new THREE.Matrix4().makeRotationZ -Math.PI / 2
    plane = new THREE.Mesh geometry
    plane.position.x = 25 * @x
    plane.position.y = 25 * @y
    plane.visible = false
    @scene.add plane
    @objects.push plane
    @planes.push plane
    # Raycaster
    @vector = new THREE.Vector3()
    @raycaster = new THREE.Raycaster()
    # Load Model
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
          material = new THREE.MeshLambertMaterial color: new THREE.Color("rgb(#{@voxels[z][y][x].r},#{@voxels[z][y][x].g},#{@voxels[z][y][x].b})"), shading: THREE.FlatShading
          material.ambient = material.color
          if @voxels[z][y][x].t in [1, 2, 4] # glass, tiled glass or glowing glass
            material.transparent = true
            material.opacity = @voxels[z][y][x].a / 255
          voxel = new THREE.Mesh new THREE.BoxGeometry(50, 50, 50), material
          voxel.position.x = x * 50 + 25
          voxel.position.y = y * 50 + 25
          voxel.position.z = z * 50 + 25
          @scene.add voxel
          @objects.push voxel
    # Lights
    @ambientLight = new THREE.AmbientLight 0x606060
    @scene.add @ambientLight
    @directionalLight = new THREE.DirectionalLight 0xffffff
    @directionalLight.position.set(1, 0.75, 0.5).normalize()
    @scene.add @directionalLight
    @renderer = new THREE.WebGLRenderer antialias: true
    @renderer.setClearColor 0x888888
    @renderer.setSize @width, @height
    @domContainer.empty().append @renderer.domElement
    # Event handlers
    @domContainer.on        'mousedown', (e) => @onDocumentMouseDown(e)
    @domContainer.on        'mousemove', (e) => @onDocumentMouseMove(e)
    document.addEventListener 'keydown', (e) => @onDocumentKeyDown(e)
    document.addEventListener   'keyup', (e) => @onDocumentKeyUp(e)
    window.addEventListener    'resize', (e) => @onWindowResize(e)
    # Stats (fps)
    unless @embedded
      @stats = new Stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '0px'
      @domContainer.append @stats.domElement
    # Controls and Camera
    @camera = new THREE.PerspectiveCamera 45, @width / @height, 1, 10000
    @camera.position.x = -50 * @y - 20 * @z - 10 * @x
    @camera.position.y = @y * 50
    @camera.position.z = @z * 25
    @controls = new THREE.OrbitControls @camera, @domContainer[0]
    @controls.target = new THREE.Vector3 @x * 25, @y * 25, @z * 25
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
    @scene.remove o for o in @objects when o not in @planes
    @objects = @planes.slice 0
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
          material = new THREE.MeshLambertMaterial color: new THREE.Color("rgb(#{@voxels[z][y][x].r},#{@voxels[z][y][x].g},#{@voxels[z][y][x].b})"), shading: THREE.FlatShading
          material.ambient = material.color
          if @voxels[z][y][x].t in [1, 2, 4] # glass, tiled glass or glowing glass
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
    @stats.update() unless @embedded

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
    @vector.set (e.clientX / @width) * 2 - 1, -((e.clientY - 50) / @height) * 2 + 1, 0.5
    @vector.unproject @camera
    @raycaster.ray.set @camera.position, @vector.sub(@camera.position).normalize()
    intersects = @raycaster.intersectObjects @objects
    if intersects.length > 0
      intersect = intersects[0]
      if e.button == 2 # right mouse button => delete cube
        if intersect.object not in @planes
          x = (intersect.object.position.x - 25) / 50
          y = (intersect.object.position.y - 25) / 50
          z = (intersect.object.position.z - 25) / 50
          delete @voxels[z][y][x]
          delete @voxels[z][y] if @voxels[z][y].filter((e) -> return e != undefined).length == 0
          delete @voxels[z] if @voxels[z].filter((e) -> return e != undefined).length == 0
          @scene.remove intersect.object
          @objects.splice @objects.indexOf(intersect.object), 1
      if e.button == 0 # left mouse button => create cube
        cubeMaterial = new THREE.MeshLambertMaterial color: new THREE.Color($('#addVoxColor').val()), shading: THREE.FlatShading
        cubeMaterial.ambient = cubeMaterial.color
        a = parseInt($('#addVoxAlpha').val())
        t = parseInt($('#addVoxType').val())
        a = 255 if t in [0, 3] # Solid
        if t in [1, 2, 4] && $('#addVoxColor').val() != '#ff00ff'
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
        @voxels[z][y][x] = switch $('#addVoxColor').val()
          when '#ff00ff' then r: 255, g: 0, b: 255, a: 250, t: 7, s: 7
          else
            r: parseInt($('#addVoxColor').val().substring(1, 3),16)
            g: parseInt($('#addVoxColor').val().substring(3, 5),16)
            b: parseInt($('#addVoxColor').val().substring(5, 7),16)
            a: a, t: t, s: parseInt($('#addVoxSpecular').val())
        @scene.add voxel
        @objects.push voxel
      if e.button == 1 # middle mouse button => color picker
        return if intersect.object in @planes
        x = (intersect.object.position.x - 25) / 50
        y = (intersect.object.position.y - 25) / 50
        z = (intersect.object.position.z - 25) / 50
        vox = @voxels[z][y][x]
        $('#addVoxColor').val('#' + new THREE.Color("rgb(#{vox.r},#{vox.g},#{vox.b})").getHexString())
        return $('#addVoxColor').change() if vox.r == vox.b == 255 and vox.g == 0
        $('#addVoxAlpha').val(vox.a)
        $('#addVoxType').val(vox.t)
        $('#addVoxSpecular').val(vox.s)
        return $('#addVoxColor').change()
      @render()

  onDocumentKeyDown: (e) ->
    return if $('.active #modeView').length == 1
    switch e.keyCode
      when 18 # Alt
        @controls.enabled = true
        @editMode = false

  onDocumentKeyUp: (e) ->
    return if $('.active #modeView').length == 1
    switch e.keyCode
      when 18 # Alt
        @controls.enabled = false
        @editMode = true

  onWindowResize: ->
    @width = @domContainer.width()
    @height = @domContainer.height() - 5
    @camera.aspect = @width / @height
    @camera.updateProjectionMatrix()
    @renderer.setSize @width, @height
    @render()

if typeof module == 'object' then module.exports = Renderer else window.Renderer = Renderer
