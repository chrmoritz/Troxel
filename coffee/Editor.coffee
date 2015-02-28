'use strict'
class Editor extends Renderer
  constructor: (io, @embedded = false, @domContainer = $('#WebGlContainer')) ->
    @objects = []
    super(io, @embedded, @domContainer, parseInt($('#renderMode').val()), parseInt($('#renderWireframes').val()), $('#rendererAntialias').val()=="1")
    # roll-over helpers
    @rollOverMesh = new THREE.Mesh new THREE.BoxGeometry(48, 48, 48), new THREE.MeshBasicMaterial wireframe: true, color: 0x000000
    @scene.add @rollOverMesh
    # Raycaster
    @vector = new THREE.Vector3()
    @raycaster = new THREE.Raycaster()
    @setupGrid()
    # Stats
    @stats = new Stats()
    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.top = '0px'
    @domContainer.append @stats.domElement
    @changeEditMode($('#modeEdit').parent().hasClass('active'))
    # Event handlers
    @domContainer.on        'mousedown', (e) => @onDocumentMouseDown(e)
    @domContainer.on        'mousemove', (e) => @onDocumentMouseMove(e)
    document.addEventListener   'keyup', (e) => @onDocumentKeyUp(e)
    @animate()

  setupGrid: ->
    #Planes
    @planes = []
    geometry = new THREE.PlaneBufferGeometry 50 * @x, 50 * @y # back plane
    geometry.applyMatrix new THREE.Matrix4().makeRotationY Math.PI / 2
    plane = new THREE.Mesh geometry
    plane.position.y = 25 * @y
    plane.position.z = 25 * @x
    plane.visible = false
    @scene.add plane
    @objects.push plane
    @planes.push plane
    geometry = new THREE.PlaneBufferGeometry 50 * @z, 50 * @x # bottom plane
    geometry.applyMatrix new THREE.Matrix4().makeRotationX -Math.PI / 2
    plane = new THREE.Mesh geometry
    plane.position.x = 25 * @z
    plane.position.z = 25 * @x
    plane.visible = false
    @scene.add plane
    @objects.push plane
    @planes.push plane
    geometry = new THREE.PlaneBufferGeometry 50 * @y, 50 * @z # left plane
    geometry.applyMatrix new THREE.Matrix4().makeRotationZ -Math.PI / 2
    geometry.applyMatrix new THREE.Matrix4().makeRotationX Math.PI
    plane = new THREE.Mesh geometry
    plane.position.x = 25 * @z
    plane.position.y = 25 * @y
    plane.position.z = 50 * @x
    plane.visible = false
    @scene.add plane
    @objects.push plane
    @planes.push plane
    # grid
    geometry = new THREE.Geometry()
    for x in [0..@x] by 1
      geometry.vertices.push new THREE.Vector3       0,       0,  50 * x # bottom grid
      geometry.vertices.push new THREE.Vector3 50 * @z,       0,  50 * x
      geometry.vertices.push new THREE.Vector3       0,       0,  50 * x # back grid
      geometry.vertices.push new THREE.Vector3       0, 50 * @y,  50 * x
    for y in [0..@y] by 1
      geometry.vertices.push new THREE.Vector3       0,  50 * y, 50 * @x # left grid
      geometry.vertices.push new THREE.Vector3 50 * @z,  50 * y, 50 * @x
      geometry.vertices.push new THREE.Vector3       0,  50 * y,       0 # back grid
      geometry.vertices.push new THREE.Vector3       0,  50 * y, 50 * @x
    for z in [0..@z] by 1
      geometry.vertices.push new THREE.Vector3  50 * z,       0,       0 # bottom grid
      geometry.vertices.push new THREE.Vector3  50 * z,       0, 50 * @x
      geometry.vertices.push new THREE.Vector3  50 * z,       0, 50 * @x # left grid
      geometry.vertices.push new THREE.Vector3  50 * z, 50 * @y, 50 * @x
    material = new THREE.LineBasicMaterial color: 0x000000, opacity: 0.2, transparent: true
    @grid = new THREE.Line geometry, material, THREE.LinePieces
    @scene.add @grid

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

  reload: (@voxels, @x, @y, @z, resize = false, init = false) ->
    if resize
      @scene.remove p for p in @planes
      @scene.remove @grid
      @setupGrid()
      @changeEditMode($('#modeEdit').parent().hasClass('active'))
    unless init
      @objects = @planes.slice 0
    super @voxels, @x, @y, @z, resize, init
    @objects.push @mesh

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
    getColor = (color, noiseBright, noiseHSL) ->
      if noiseBright > 0
        color.multiplyScalar Math.random() * 2 * noiseBright + 1 - noiseBright
        color.r = 1 if color.r > 1
        color.g = 1 if color.g > 1
        color.b = 1 if color.b > 1
      if noiseHSL > 0
        hsl = color.getHSL()
        hsl.h = (hsl.h + 0.1 * (Math.random() * 2 * noiseHSL - noiseHSL)) %% 1
        hsl.s = Math.max(0, Math.min(1, hsl.s + Math.random() * 2 * noiseHSL - noiseHSL))
        hsl.l = Math.max(0, Math.min(1, hsl.l + Math.random() * 2 * noiseHSL - noiseHSL))
        color.setHSL hsl.h, hsl.s, hsl.l
      return color
    @vector.set (e.clientX / @width) * 2 - 1, -((e.clientY - 50) / @height) * 2 + 1, 0.5
    @vector.unproject @camera
    @raycaster.ray.set @camera.position, @vector.sub(@camera.position).normalize()
    intersects = @raycaster.intersectObjects @objects
    if intersects.length > 0
      intersect = intersects[0]
      switch e.button
        when 0 # left mouse button
          switch $('.active .editTool').data('edittool')
            when 0 # add voxel
              color = getColor new THREE.Color($('#addVoxColor').val()), parseFloat $('#editVoxNoiseBright').val(), parseFloat $('#editVoxNoiseHSL').val()
              a = parseInt($('#addVoxAlpha').val())
              t = parseInt($('#addVoxType').val())
              s = parseInt($('#addVoxSpecular').val())
              a = 255 if t in [0, 3] # Solid
              if $('#addVoxColor').val() == '#ff00ff'
                a = 250
                t = s = 7
              intersect.point.add(intersect.face.normal).divideScalar(50).floor()
              x = intersect.point.z
              y = intersect.point.y
              z = intersect.point.x
              return unless 0 <= x < @x and 0 <= y < @y and 0 <= z < @z
              @voxels[z] = [] unless @voxels[z]?
              @voxels[z][y] = [] unless @voxels[z][y]?
              @voxels[z][y][x] = r: Math.floor(color.r * 255), g: Math.floor(color.g * 255), b: Math.floor(color.b * 255), a: a, t: t, s: s
            when 1 # fill single voxel
              return if intersect.object in @planes
              intersect.point.add(intersect.face.normal).divideScalar(50).floor().sub(intersect.face.normal)
              x = intersect.point.z
              y = intersect.point.y
              z = intersect.point.x
              color = getColor new THREE.Color($('#addVoxColor').val()), parseFloat $('#editVoxNoiseBright').val(), parseFloat $('#editVoxNoiseHSL').val()
              a = parseInt($('#addVoxAlpha').val())
              t = parseInt($('#addVoxType').val())
              s = parseInt($('#addVoxSpecular').val())
              a = 255 if t in [0, 3] # Solid
              if color.r == 1 and color.g == 0 and color.b == 1
                a = 250
                t = s = 7
              @voxels[z][y][x].r = Math.floor(color.r * 255)
              @voxels[z][y][x].g = Math.floor(color.g * 255)
              @voxels[z][y][x].b = Math.floor(color.b * 255)
              @voxels[z][y][x].a = a
              @voxels[z][y][x].t = t
              @voxels[z][y][x].s = s
        when 2 # right mouse button
          return if intersect.object in @planes
          intersect.point.add(intersect.face.normal).divideScalar(50).floor().sub(intersect.face.normal)
          x = intersect.point.z
          y = intersect.point.y
          z = intersect.point.x
          switch $('.active .editTool').data('edittool')
            when 0 # delete cube
              delete @voxels[z][y][x]
              delete @voxels[z][y] if @voxels[z][y].filter((e) -> return e != undefined).length == 0
              delete @voxels[z] if @voxels[z].filter((e) -> return e != undefined).length == 0
            when 1 # fill area
              connected = (z, y, x) -> @voxels[z]?[y]?[x]? and !@voxels[z][y][x].filled and (!colorMatch or (v.r == @voxels[z][y][x].r and
                  v.g == @voxels[z][y][x].g and v.b == @voxels[z][y][x].b and v.a == @voxels[z][y][x].a and v.t == @voxels[z][y][x].t and v.s == @voxels[z][y][x].s))
              baseColor = new THREE.Color $('#addVoxColor').val()
              noiseBright = parseFloat $('#editVoxNoiseBright').val()
              noiseRgb = parseFloat $('#editVoxNoiseHSL').val()
              colorMatch = $('#fillSameColor').prop('checked')
              a = parseInt($('#addVoxAlpha').val())
              t = parseInt($('#addVoxType').val())
              s = parseInt($('#addVoxSpecular').val())
              a = 255 if t in [0, 3] # Solid
              return if baseColor.getHex() == 0xff00ff # no fill for attachment points
              toFill = [[z, y, x]]
              @voxels[z][y][x].filled = true
              color = new THREE.Color() # dummy color
              while toFill.length > 0
                [z, y, x] = toFill.pop()
                v = {r: @voxels[z][y][x].r, g: @voxels[z][y][x].g, b: @voxels[z][y][x].b, a: @voxels[z][y][x].a, t: @voxels[z][y][x].t, s: @voxels[z][y][x].s}
                color = getColor color.copy(baseColor), noiseBright, noiseRgb
                @voxels[z][y][x].r = Math.floor(color.r * 255)
                @voxels[z][y][x].g = Math.floor(color.g * 255)
                @voxels[z][y][x].b = Math.floor(color.b * 255)
                @voxels[z][y][x].g = 1 if color.r == 1 and color.g == 0 and color.b == 1 # prevent random attachment points
                @voxels[z][y][x].a = a
                @voxels[z][y][x].t = t
                @voxels[z][y][x].s = s
                (@voxels[z    ][y    ][x + 1].filled = true; toFill.push [z    , y    , x + 1]) if connected.call @, z    , y    , x + 1
                (@voxels[z    ][y    ][x - 1].filled = true; toFill.push [z    , y    , x - 1]) if connected.call @, z    , y    , x - 1
                (@voxels[z    ][y + 1][x    ].filled = true; toFill.push [z    , y + 1, x    ]) if connected.call @, z    , y + 1, x
                (@voxels[z    ][y - 1][x    ].filled = true; toFill.push [z    , y - 1, x    ]) if connected.call @, z    , y - 1, x
                (@voxels[z + 1][y    ][x    ].filled = true; toFill.push [z + 1, y    , x    ]) if connected.call @, z + 1, y    , x
                (@voxels[z - 1][y    ][x    ].filled = true; toFill.push [z - 1, y    , x    ]) if connected.call @, z - 1, y    , x
              for z in [0...@z] by 1 when @voxels[z]?
                for y in [0...@y] by 1 when @voxels[z]?[y]?
                  for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
                    delete @voxels[z][y][x].filled if @voxels[z][y][x].filled
        when 1 # middle mouse button => color picker
          return if intersect.object in @planes
          intersect.point.add(intersect.face.normal).divideScalar(50).floor().sub(intersect.face.normal)
          x = intersect.point.z
          y = intersect.point.y
          z = intersect.point.x
          vox = @voxels[z][y][x]
          $('#addVoxColor').val('#' + new THREE.Color(vox.r / 255, vox.g / 255, vox.b / 255).getHexString())
          return $('#addVoxColor').change() if vox.r == vox.b == 255 and vox.g == 0
          $('#addVoxAlpha').val(vox.a)
          $('#addVoxType').val(vox.t)
          $('#addVoxSpecular').val(vox.s)
          return $('#addVoxColor').change()
      @reload @voxels, @x, @y, @z
      ioo = {voxels: @voxels, x: @x, y: @y, z: @z}
      base64 = new Base64IO(ioo).export false
      try
        history.pushState ioo, 'Troxel', '#m=' + base64
      catch # reached the quota lime of state object (640k on firefox)
        history.pushState null, 'Troxel', '#m=' + base64
      @render()

  onDocumentKeyDown: (e) ->
    return unless super(e)?
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

if typeof module == 'object' then module.exports = Editor else window.Editor = Editor
