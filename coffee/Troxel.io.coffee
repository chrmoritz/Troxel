'use strict'
class Base64IO extends IO
  constructor: (base64) ->
    return if super(base64)
    @voxels = []
    [@x, @y, @z, @readonly, data...] = atob(base64).split('').map (c) -> c.charCodeAt 0
    i = r = 0 # i: pointer to position in data, r: repeat counter
    vox = {}
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1
          if r == 0
            if data[i] > 127 # read repeat value
              r = data[i] - 127
              i++
            else
              r = 1
            throw new Error "Base64 parsing error" if data[i] > 127
            if data[i] < 64 # cache vox data
              vox = {r: data[i + 1], g: data[i + 2], b: data[i + 3], a: data[i + 4], s: data[i] % 8, t: data[i] >> 3}
              i += 5
            else
              vox = null
              i++
          if vox? # apply vox data repeat often (if vox not empty)
            @voxels[z] = [] unless @voxels[z]?
            @voxels[z][y] = [] unless @voxels[z][y]?
            @voxels[z][y][x] = {r: vox.r, g: vox.g, b: vox.b, a: vox.a, s: vox.s, t: vox.t}
          r--
    console.warn "There shouldn't be any bytes left" unless i == data.length
    console.log "voxels:" unless @readonly
    console.log @voxels unless @readonly

  export: (readonly) ->
    equal = (a, b, index) ->
      return false unless index < vox.length # check if last voxes is reached
      return true if !a? and !b?
      return false if !a? or !b?
      return false for i in ['r', 'g', 'b', 'a', 't', 's'] when a[i] != b[i]
      return true
    data = [@x, @y, @z, if readonly then 1 else 0]
    vox = []
    vox.push(@voxels[z]?[y]?[x]) for x in [0...@x] by 1 for y in [0...@y] by 1 for z in [0...@z] by 1 # 3d to 1d array
    i = 0
    while i < vox.length
      r = 1 # repeat
      (if equal vox[i + r - 1], vox[i + r], i + r then r++ else break) while r < 128
      data.push 127 + r if r > 1 # 1xxxxxxx wheree x^7 = r - 1
      if vox[i]?
        data = data.concat [8 * vox[i].t + vox[i].s, vox[i].r, vox[i].g, vox[i].b, vox[i].a] # 00tttsss where t^3 is type and s^3 specular followed by r^8 g^8 b^8 a^8
      else
        data.push 64 # 01000000 for empty
      i += r
    console.log "export base64:"
    console.log data
    btoa String.fromCharCode.apply null, data

class JsonIO extends IO
  constructor: (json) ->
    return if super(json)
    {x: @x, y: @y, z: @z, voxels: @voxels} = JSON.parse json

  export: (pretty) ->
    JSON.stringify {x: @x, y: @y, z: @z, voxels: @voxels}, null, if pretty then '    ' else ''

(exports ? window).Base64IO = Base64IO
(exports ? window).JsonIO = JsonIO
