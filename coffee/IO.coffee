class IO
  constructor: (other) ->
    if (other instanceof IO) or (typeof other == 'object' and other.x? and other.y? and other.z? and other.voxels?)
      @voxels = other.voxels
      @x = other.x
      @y = other.y
      @z = other.z
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
          return false unless typeof x.a == 'number' and x.a in [250, 16, 48, 80, 112, 144, 176, 208, 240, 255]
          return false unless typeof x.t == 'number' and (0 <= x.t <= 4 or x.t == 7)
          return false unless typeof x.s == 'number' and (0 <= x.s <= 3 or x.s == 7)
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

if typeof module == 'object' then module.exports = IO else window.IO = IO
