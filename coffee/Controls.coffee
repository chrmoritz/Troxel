class THREE.TroxelControls extends THREE.EventDispatcher
  constructor: (@object, @domElement) ->
    # API
    @enabled = true
    @mode = true # true for Orbital and false for Fly controls
    @target = new THREE.Vector3() # target sets the location of focus, where the control orbits around and where it pans with respect to.
    @noZoom = false
    @zoomSpeed = 0.95 # < 1.0
    @minDistance = 0
    @maxDistance = Infinity
    @noRotate = false
    @rotateSpeed = 1.0
    @noPan = false
    @autoRotate = false
    @autoRotateSpeed = -4.0
    @noKeys = false
    # internals
    @needsRender = false
    @EPS = 0.000001
    @rotateStart = new THREE.Vector2()
    @rotateEnd = new THREE.Vector2()
    @rotateDelta = new THREE.Vector2()
    @panStart = new THREE.Vector2()
    @panEnd = new THREE.Vector2()
    @panDelta = new THREE.Vector2()
    @panOffset = new THREE.Vector3()
    @offset = new THREE.Vector3()
    @dollyStart = new THREE.Vector2()
    @dollyEnd = new THREE.Vector2()
    @dollyDelta = new THREE.Vector2()
    @theta = 0
    @phi = 0
    @phiDelta = 0
    @thetaDelta = 0
    @scale = 1
    @pan = new THREE.Vector3()
    @lastPosition = new THREE.Vector3()
    @lastQuaternion = new THREE.Quaternion()
    @STATE = NONE: -1, ROTATE: 0, DOLLY: 1, PAN: 2, TOUCH_ROTATE: 3, TOUCH_DOLLY: 4, TOUCH_PAN: 5, FLY: 6
    @state = @STATE.NONE
    @target0 = @target.clone()
    @position0 = @object.position.clone()
    @quat = new THREE.Quaternion().setFromUnitVectors @object.up, new THREE.Vector3 0, 1, 0  # so camera.up is the orbit axis
    @quatInverse = @quat.clone().inverse()
    # Fly Controls internals
    @moveVector = new THREE.Vector3()
    @rotationVector = new THREE.Vector3()
    @tmpQuaternion = new THREE.Quaternion()
    @mousefly = false
    # Event handlers
    @domElement.addEventListener 'contextmenu', (e) -> e.preventDefault()
    @domElement.addEventListener 'mousedown', (e) => @onMouseDown(e)
    document.addEventListener 'mouseup', (e) => @onMouseUp(e)
    document.addEventListener 'mousemove', (e) => @onMouseMove(e)
    @domElement.addEventListener 'mousewheel', (e) => @onMouseWheel(e)
    @domElement.addEventListener 'DOMMouseScroll', (e) => @onMouseWheel(e) # firefox
    @domElement.addEventListener 'touchstart', (e) => @touchstart(e)
    @domElement.addEventListener 'touchend', (e) => @touchend(e)
    @domElement.addEventListener 'touchmove', (e) => @touchmove(e)
    window.addEventListener 'keydown', (e) => @onKeyDown(e)
    window.addEventListener 'keyup', (e) => @onKeyUp(e)
    @object.lookAt @target
    @update() # force an update at start

  rotateLeft: (angle) ->
    angle = 2 * Math.PI / 60 / 60 * @autoRotateSpeed unless angle?
    @thetaDelta -= angle

  rotateUp: (angle) ->
    angle = 2 * Math.PI / 60 / 60 * @autoRotateSpeed unless angle?
    @phiDelta -= angle

  panLeft: (distance) -> # pass in distance in world space to move left
    te = @object.matrix.elements
    @panOffset.set te[0], te[1], te[2] # get X column of matrix
    @panOffset.multiplyScalar -distance
    @pan.add @panOffset

  panUp: (distance) -> # pass in distance in world space to move up
    te = @object.matrix.elements
    @panOffset.set te[4], te[5], te[6] # get Y column of matrix
    @panOffset.multiplyScalar distance
    @pan.add @panOffset

  panXY: (deltaX, deltaY) -> # pass in x,y of change desired in pixel space, right and down are positive
    if @object instanceof THREE.PerspectiveCamera
      position = @object.position
      targetDistance = position.clone().sub(@target).length()
      targetDistance *= Math.tan (@object.fov / 2) * Math.PI / 180.0 # half of the fov is center to top of screen
      @panLeft 2 * deltaX * targetDistance / @domElement.clientHeight # we actually don't use screenWidth, since perspective camera is fixed to screen height
      @panUp 2 * deltaY * targetDistance / @domElement.clientHeight
    else
      console.warn 'WARNING: Controls.js only supports perspective camera type.'

  dollyIn: (dollyScale) ->
    dollyScale = @zoomSpeed unless dollyScale?
    @scale /= dollyScale

  dollyOut: (dollyScale) ->
    dollyScale = @zoomSpeed unless dollyScale?
    @scale *= dollyScale

  update: ->
    if @mode # Orbital Controls
      position = @object.position
      @offset.copy(position).sub @target
      @offset.applyQuaternion @quat # rotate offset to "y-axis-is-up" space
      @theta = Math.atan2 @offset.x, @offset.z # angle from z-axis around y-axis
      @phi = Math.atan2(Math.sqrt(@offset.x * @offset.x + @offset.z * @offset.z ), @offset.y) # angle from y-axis
      @rotateLeft 2 * Math.PI / 60 / 60 * @autoRotateSpeed if @autoRotate and @state == @STATE.NONE
      @theta += @thetaDelta
      @phi += @phiDelta
      @phi = Math.max @EPS, Math.min Math.PI - @EPS, @phi # restrict phi to be betwee EPS and PI-EPS
      radius = @offset.length() * @scale
      radius = Math.max @minDistance, Math.min @maxDistance, radius # restrict radius to be between desired limits
      @target.add @pan # move target to panned location
      @offset.x = radius * Math.sin(@phi) * Math.sin(@theta)
      @offset.y = radius * Math.cos(@phi)
      @offset.z = radius * Math.sin(@phi) * Math.cos(@theta)
      @offset.applyQuaternion @quatInverse # rotate offset back to "camera-up-vector-is-up" space
      position.copy(@target).add @offset
      @object.lookAt @target
      @thetaDelta = 0
      @phiDelta = 0
      @scale = 1
      @pan.set 0, 0, 0
    else # Fly Controls
      @object.translateX @moveVector.x * 20
      @object.translateY @moveVector.y * 20
      @object.translateZ @moveVector.z * 20
      @tmpQuaternion.set(@rotationVector.x * 0.005, @rotationVector.y * 0.005, @rotationVector.z * 0.005, 1).normalize()
      @object.quaternion.multiply @tmpQuaternion
      @object.rotation.setFromQuaternion @object.quaternion, @object.rotation.order # expose the rotation vector for convenience
    # update condition is: min(camera displacement, camera rotation in radians)^2 > EPS using small-angle approximation cos(x/2) = 1 - x^2 / 8
    if @lastPosition.distanceToSquared(@object.position) > @EPS || 8 * (1 - @lastQuaternion.dot(@object.quaternion)) > @EPS
      @dispatchEvent type: 'change'
      @lastPosition.copy @object.position
      @lastQuaternion.copy @object.quaternion
      @needsRender = false
    if @needsRender
      console.log 'needsRender'
      @dispatchEvent type: 'change'
      @needsRender = false

  reset = ->
    @state = @STATE.NONE
    @target.copy @target0
    @object.position.copy @position0
    @object.updateProjectionMatrix()
    @dispatchEvent type: 'change'
    @update()

  onMouseDown: (e) ->
    return unless @enabled
    e.preventDefault()
    if @mode # Orbital Controls
      if e.button == 0 # left moude button
        return if @noRotate
        @state = @STATE.ROTATE
        @rotateStart.set e.clientX, e.clientY
      else if e.button == 1 # middle mouse button
        return if @noZoom
        @state = @STATE.DOLLY
        @dollyStart.set e.clientX, e.clientY
      else if e.button == 2 # right mouse button
        return if @noPan
        @state = @STATE.PAN
        @panStart.set e.clientX, e.clientY
    else # Fly Controls
      @mousefly = true
      @state = @STATE.FLY
      if e.button == 0 # left mouse button
        @moveVector.z = -1
      else if e.button == 2 # right mouse button
        @moveVector.z = 1
    @dispatchEvent type: 'start' if @state != @STATE.NONE

  onMouseMove: (e) ->
    return unless @enabled
    e.preventDefault()
    if @state == @STATE.ROTATE
      return if @noRotate
      @rotateEnd.set e.clientX, e.clientY
      @rotateDelta.subVectors @rotateEnd, @rotateStart
      @rotateLeft 2 * Math.PI * @rotateDelta.x / @domElement.clientWidth * @rotateSpeed # rotating across whole screen goes 360 degrees around
      @rotateUp 2 * Math.PI * @rotateDelta.y / @domElement.clientHeight * @rotateSpeed # rotating up and down along whole screen attempts to go 360, but limited to 180
      @rotateStart.copy @rotateEnd
    else if @state == @STATE.DOLLY
      return if @noZoom
      @dollyEnd.set e.clientX, e.clientY
      @dollyDelta.subVectors @dollyEnd, @dollyStart
      if @dollyDelta.y > 0
        @dollyIn()
      else if @dollyDelta.y < 0
        @dollyOut()
      @dollyStart.copy @dollyEnd
    else if @state == @STATE.PAN
      return if @noPan
      @panEnd.set e.clientX, e.clientY
      @panDelta.subVectors @panEnd, @panStart
      @panXY @panDelta.x, @panDelta.y
      @panStart.copy @panEnd
    else if @mousefly
      w = @domElement.clientWidth / 2
      h = @domElement.clientHeight / 2
      @rotationVector.y = -(e.clientX - w) / w
      @rotationVector.x = -(e.clientY - h) / h
    @update() if @state != @STATE.NONE and @mode

  onMouseUp: ->
    return unless @enabled
    @moveVector.z = 0
    @dispatchEvent type: 'end'
    @state = @STATE.NONE

  onMouseWheel: (e) ->
    return if !@enabled or @noZoom or @state != @STATE.NONE or !@mode
    e.preventDefault()
    e.stopPropagation()
    delta = 0
    if e.wheelDelta? # WebKit / Opera / Explorer 9
      delta = e.wheelDelta
    else if e.detail? # Firefox
      delta = - e.detail
    if delta > 0
      @dollyOut()
    else if delta < 0
      @dollyIn()
    @update()
    @dispatchEvent type: 'start'
    @dispatchEvent type: 'end'

  onKeyDown: (e) ->
    return if !@enabled or @noKeys
    if @mode # Orbital Controls
      unless @noRotate
        switch e.keyCode
          when 87 then @rotateUp -0.05; @update() # W
          when 65 then @rotateLeft -0.05; @update() # A
          when 83 then @rotateUp 0.05; @update() # S
          when 68 then @rotateLeft 0.05; @update() # D
      unless @noZoom
        switch e.keyCode
          when 81 then @dollyIn(); @update() # Q
          when 69 then @dollyOut(); @update() # E
      unless @noPan
        switch e.keyCode
          when 38 then @panXY 0, 7.0; @update() # up arrow key
          when 40 then @panXY 0, -7.0; @update() # down arrow key
          when 37 then @panXY 7.0, 0; @update() # left arrow key
          when 39 then @panXY -7.0, 0; @update() # right arrow key
    else # Fly Controls
      (@rotationVector.set(0, 0, 0); @mousefly = false) if @mousefly
      switch e.keyCode
        when 87 then @moveVector.z = -1 # W
        when 83 then @moveVector.z = 1 # S
        when 65 then @moveVector.x = -1 # A
        when 68 then @moveVector.x = 1 # D
        when 82 then @moveVector.y = 1 # R
        when 70 then @moveVector.y = -1 # F
        when 38 then @rotationVector.x = -1 # up arrow key
        when 40 then @rotationVector.x = 1 # down arrow key
        when 37 then @rotationVector.y = 1 # left arrow key
        when 39 then @rotationVector.y = -1 # right arrow key
        when 81 then @rotationVector.z = 1 # Q
        when 69 then @rotationVector.z = -1 # E

  onKeyUp: (e) ->
    return if !@enabled or @noKeys or @mode
    switch e.keyCode
      when 87 then @moveVector.z = 0 # W
      when 83 then @moveVector.z = 0 # S
      when 65 then @moveVector.x = 0 # A
      when 68 then @moveVector.x = 0 # D
      when 82 then @moveVector.y = 0 # R
      when 70 then @moveVector.y = 0 # F
      when 38 then @rotationVector.x = 0 # up arrow key
      when 40 then @rotationVector.x = 0 # down arrow key
      when 37 then @rotationVector.y = 0 # left arrow key
      when 39 then @rotationVector.y = 0 # right arrow key
      when 81 then @rotationVector.z = 0 # Q
      when 69 then @rotationVector.z = 0 # E

  touchstart: (e) ->
    return unless @enabled and @mode
    switch e.touches.length
      when 1 # one-fingered touch: rotate
        return if @noRotate
        @state = @STATE.TOUCH_ROTATE
        @rotateStart.set e.touches[0].pageX, e.touches[0].pageY
      when 2 # two-fingered touch: dolly
        return if @noZoom
        @state = @STATE.TOUCH_DOLLY
        dx = e.touches[0].pageX - e.touches[1].pageX
        dy = e.touches[0].pageY - e.touches[1].pageY
        @dollyStart.set 0, Math.sqrt dx * dx + dy * dy
      when 3 # three-fingered touch: pan
        return if @noPan
        @state = @STATE.TOUCH_PAN
        @panStart.set e.touches[0].pageX, e.touches[0].pageY
      else
        @state = @STATE.NONE
    @dispatchEvent type: 'start' if @state != @STATE.NONE

  touchmove: (e) ->
    return unless @enabled and @mode
    e.preventDefault()
    e.stopPropagation()
    switch e.touches.length
      when 1 # one-fingered touch: rotate
        return if @noRotate or @state != @STATE.TOUCH_ROTATE
        @rotateEnd.set e.touches[0].pageX, e.touches[0].pageY
        @rotateDelta.subVectors @rotateEnd, @rotateStart
        @rotateLeft 2 * Math.PI * @rotateDelta.x / @domElement.clientWidth * @rotateSpeed # rotating across whole screen goes 360 degrees around
        @rotateUp 2 * Math.PI * @rotateDelta.y / @domElement.clientHeight * @rotateSpeed # rotating up and down along whole screen attempts to go 360, but limited to 180
        @rotateStart.copy @rotateEnd
        @update()
      when 2 # two-fingered touch: dolly
        return if @noZoom or @state != @STATE.TOUCH_DOLLY
        dx = e.touches[0].pageX - e.touches[1].pageX
        dy = e.touches[0].pageY - e.touches[1].pageY
        @dollyEnd.set 0, Math.sqrt dx * dx + dy * dy
        @dollyDelta.subVectors @dollyEnd, @dollyStart
        if @dollyDelta.y > 0
          @dollyOut()
        else if @dollyDelta.y < 0
          @dollyIn()
        @dollyStart.copy @dollyEnd
        @update()
      when 3 # three-fingered touch: pan
        return if @noPan or @state != @STATE.TOUCH_PAN
        @panEnd.set e.touches[0].pageX, e.touches[0].pageY
        @panDelta.subVectors @panEnd, @panStart
        @panXY @panDelta.x, @panDelta.y
        @panStart.copy @panEnd
        @update()
      else
        @state = @STATE.NONE

  touchend: ->
    return unless @enabled and @mode
    @dispatchEvent type: 'end'
    @state = @STATE.NONE
