'use strict'
class IO
  constructor: (other) ->
    if (other instanceof IO) or (typeof other == 'object' and other.x? and other.y? and other.z? and other.voxels?)
      @voxels = other.voxels
      @x = other.x
      @y = other.y
      @z = other.z
      @readonly = true if other.readonly
      return true

  verify: ->
    return false unless @x? and @y? and @z? and @voxels?
    return false unless @x > 0 and @y > 0 and @z > 0 and Array.isArray(@voxels)
    return false if @voxels.length > @z
    for z in @voxels
      return false if not Array.isArray(z) or z.length > @y
      for y in z
        return false if not Array.isArray(y) or y.length > @x
        for x in y
          return false unless typeof x == 'object'
          return false unless typeof x.r == 'number' and 0 <= x.r <= 255
          return false unless typeof x.g == 'number' and 0 <= x.g <= 255
          return false unless typeof x.b == 'number' and 0 <= x.b <= 255
          if x.r == 255 and x.g == 0 and x.b = 255 # attachment point
            return false unless typeof x.a == 'number' and x.a == 250
            return false unless typeof x.t == 'number' and x.t == 7
            return false unless typeof x.s == 'number' and x.s == 7
          else
            return false unless typeof x.a == 'number' and x.a in [16, 48, 80, 112, 144, 176, 208, 240, 255]
            return false unless typeof x.t == 'number' and 0 <= x.t <= 4
            return false unless typeof x.s == 'number' and 0 <= x.s <= 3
    return true

  rotateX: (d) ->
    voxels = @voxels.slice 0
    @voxels = []
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when voxels[if d then @z - z - 1 else z]?[if d then y else @y - y - 1]?[x]?
          @voxels[y] = [] unless @voxels[y]?
          @voxels[y][z] = [] unless @voxels[y][z]?
          @voxels[y][z][x] = voxels[if d then @z - z - 1 else z][if d then y else @y - y - 1][x]
    [@z, @y] = [@y, @z]

  rotateY: (d) ->
    voxels = @voxels.slice 0
    @voxels = []
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when voxels[if d then @z - z - 1 else z]?[y]?[if d then x else @x - x - 1]?
          @voxels[x] = [] unless @voxels[x]?
          @voxels[x][y] = [] unless @voxels[x][y]?
          @voxels[x][y][z] = voxels[if d then @z - z - 1 else z][y][if d then x else @x - x - 1]
    [@z, @x] = [@x, @z]

  rotateZ: (d) ->
    voxels = @voxels.slice 0
    @voxels = []
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when voxels[z]?[if d then y else @y - y - 1]?[if d then @x - x - 1 else x]?
          @voxels[z] = [] unless @voxels[z]?
          @voxels[z][x] = [] unless @voxels[z][x]?
          @voxels[z][x][y] = voxels[z][if d then y else @y - y - 1][if d then @x - x - 1 else x]
    [@y, @x] = [@x, @y]

  mirrorX: ->
    voxels = @voxels.slice 0
    @voxels = []
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when voxels[z]?[y]?[@x - x - 1]?
          @voxels[z] = [] unless @voxels[z]?
          @voxels[z][y] = [] unless @voxels[z][y]?
          @voxels[z][y][x] = voxels[z][y][@x - x - 1]

  mirrorY: ->
    voxels = @voxels.slice 0
    @voxels = []
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when voxels[z]?[@y - y - 1]?[x]?
          @voxels[z] = [] unless @voxels[z]?
          @voxels[z][y] = [] unless @voxels[z][y]?
          @voxels[z][y][x] = voxels[z][@y - y - 1][x]

  mirrorZ: ->
    voxels = @voxels.slice 0
    @voxels = []
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when voxels[@z - z - 1]?[y]?[x]?
          @voxels[z] = [] unless @voxels[z]?
          @voxels[z][y] = [] unless @voxels[z][y]?
          @voxels[z][y][x] = voxels[@z - z - 1][y][x]

  moveX: (d) ->
    for z in [0...@z] by 1 when @voxels[z]?
      for y in [0...@y] by 1 when @voxels[z]?[y]?
        x0 = @voxels[z][y][if d then 0 else @x - 1]
        for x in [0...@x - 1] by 1
          if @voxels[z]?[y]?[if d then x + 1 else @x - 2 - x]?
            @voxels[z][y][if d then x else @x - 1 - x] = @voxels[z][y][if d then x + 1 else @x - 2 - x]
          else
            delete @voxels[z][y][if d then x else @x - 1 - x]
        if x0?
          @voxels[z][y][if d then @x - 1 else 0] = x0
        else
          delete @voxels[z][y][if d then @x - 1 else 0]

  moveY: (d) ->
    for z in [0...@z] by 1 when @voxels[z]?
      y0 = @voxels[z][if d then 0 else @y - 1]
      for y in [0...@y - 1] by 1
        if @voxels[z]?[if d then y + 1 else @y - 2 - y]?
          @voxels[z][if d then y else @y - 1 - y] = @voxels[z][if d then y + 1 else @y - 2 - y]
        else
          delete @voxels[z][if d then y else @y - 1 - y]
      if y0?
        @voxels[z][if d then @y - 1 else 0] = y0
      else
        delete @voxels[z][if d then @y - 1 else 0]

  moveZ: (d) ->
    z0 = @voxels[if d then 0 else @z - 1]
    for z in [0...@z - 1] by 1
      if @voxels[if d then z + 1 else @z - 2 - z]?
        @voxels[if d then z else @z - 1 - z] = @voxels[if d then z + 1 else @z - 2 - z]
      else
        delete @voxels[if d then z else @z - 1 - z]
    if z0?
      @voxels[if d then @z - 1 else 0] = z0
    else
      delete @voxels[if d then @z - 1 else 0]

  resize: (@x, @y, @z, ox, oy, oz) ->
    if oz >= 0
      @voxels = @voxels.slice oz, @z + oz
    else
      @voxels.unshift.apply @voxels, Array(-oz)
      @voxels = @voxels.slice 0, @z
    for z in [0...@z] by 1 when @voxels[z]?
      if oy >= 0
        @voxels[z] = @voxels[z].slice oy, @y + oy
      else
        @voxels[z].unshift.apply @voxels[z], Array(-oy)
        @voxels[z] = @voxels[z].slice 0, @y
      for y in [0...@y] by 1 when @voxels[z][y]?
        if ox >= 0
          @voxels[z][y] = @voxels[z][y].slice ox, @x + ox
        else
          @voxels[z][y].unshift.apply @voxels[z][y], Array(-ox)
          @voxels[z][y] = @voxels[z][y].slice 0, @x

  computeBoundingBox: ->
    maxX = maxY = maxZ = 0
    minX = @x - 1
    minY = @y - 1
    minZ = @z - 1
    for z in [0...@z] by 1 when @voxels[z]?
      minZ = Math.min minZ, z
      maxZ = Math.max maxZ, z
      for y in [0...@y] by 1 when @voxels[z][y]?
        minY = Math.min minY, y
        maxY = Math.max maxY, y
        for x in [0...@x] by 1 when @voxels[z][y][x]?
          minX = Math.min minX, x
          maxX = Math.max maxX, x
    return [@x, @y, @z, 0, 0, 0] if maxX == 0 # empty model
    return [maxX - minX + 1, maxY - minY + 1, maxZ - minZ + 1, minX, minY, minZ]

  getAttachmentPoint: ->
    for z in [0...@z] by 1 when @voxels[z]?
      for y in [0...@y] by 1 when @voxels[z][y]?
        for x in [0...@x] by 1 when @voxels[z][y][x]? and @voxels[z][y][x].t == 7
          return [x, y, z]
    return [0, 0, 0]

  merge: (mio, offsets = {x: 0, y: 0, z: 0}, relativeAP) ->
    return unless mio.x? and mio.y? and mio.z? and mio.voxels?
    @readonly = true if mio.readonly
    if relativeAP
      [apx, apy, apz] = mio.getAttachmentPoint()
      offsets.x -= apx
      offsets.y -= apy
      offsets.z -= apz
    if offsets.x < 0 or offsets.y < 0 or offsets.z < 0
      rx = Math.min 0, offsets.x
      ry = Math.min 0, offsets.y
      rz = Math.min 0, offsets.z
      @resize @x - rx, @y - ry, @z - rz, rx, ry, rz
      offsets.x = Math.max 0, offsets.x
      offsets.y = Math.max 0, offsets.y
      offsets.z = Math.max 0, offsets.z
    @x = Math.max @x, mio.x + offsets.x
    @y = Math.max @y, mio.y + offsets.y
    @z = Math.max @z, mio.z + offsets.z
    for z in [offsets.z...@z] by 1 when mio.voxels[z - offsets.z]?
      @voxels[z] = [] unless @voxels[z]?
      for y in [offsets.y...@y] by 1 when mio.voxels[z - offsets.z][y - offsets.y]?
        @voxels[z][y] = [] unless @voxels[z][y]?
        for x in [offsets.x...@x] by 1 when mio.voxels[z - offsets.z][y - offsets.y][x - offsets.x]?
          @voxels[z][y][x] = mio.voxels[z - offsets.z][y - offsets.y][x - offsets.x]
    return

if typeof module == 'object' then module.exports = IO else window.IO = IO
