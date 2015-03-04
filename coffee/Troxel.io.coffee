'use strict'
class Base64IO extends IO
  constructor: (base64) ->
    return if super(base64)
    @voxels = []
    [@x, @y, @z, @readonly, data...] = atob(base64).split('').map (c) -> c.charCodeAt 0
    i = r = 0 # i: pointer to position in data, r: repeat counter
    vox = {}
    if data[0] == 85
      paletteSize = 256 * data[1] + data[2]
      short = if data[1] == 0 then 1 else 2
      palette = [null]
      palette.push {r: data[j + 1], g: data[j + 2], b: data[j + 3], a: data[j + 4], s: data[j] % 16, t: data[j] >> 4} for j in [3...paletteSize * 5 + 3] by 5
      i = paletteSize * 5 + 3
      for z in [0...@z] by 1
        for y in [0...@y] by 1
          for x in [0...@x] by 1
            if r == 0
              if data[i] > 127 # read repeat value
                r = data[i] - 126
                i++
              else
                r = 1
              if short == 1
                index = data[i]
              else
                index = data[i] * 256 + data[i + 1]
              if index != 0 # cache vox data
                vox = palette[index]
              else
                vox = null
              i += short
            if vox? # apply vox data repeat often (if vox not empty)
              @voxels[z] = [] unless @voxels[z]?
              @voxels[z][y] = [] unless @voxels[z][y]?
              @voxels[z][y][x] = {r: vox.r, g: vox.g, b: vox.b, a: vox.a, s: vox.s, t: vox.t}
            r--
    else
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

  export: (readonly, version = 1) ->
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
    if version == 1
      while i < vox.length
        r = 1 # repeat
        (if equal vox[i + r - 1], vox[i + r], i + r then r++ else break) while r < 128
        data.push 127 + r if r > 1 # 1xxxxxxx wheree x^7 = r - 1
        if vox[i]?
          data.push 8 * vox[i].t + vox[i].s, vox[i].r, vox[i].g, vox[i].b, vox[i].a # 00tttsss where t^3 is type and s^3 specular followed by r^8 g^8 b^8 a^8
        else
          data.push 64 # 01000000 for empty
        i += r
    if version == 2
      data.push 85, 0, 0 # 01010101 for version 2 and 2 byte palette length placeholder
      rcolors = []
      for v in vox when v?
        hex = v.b + 256 * v.g + 65536 * v.r
        mat = v.a + 256 * v.t + 2048 * v.s
        rcolors[hex] = [] unless rcolors[hex]?
        unless rcolors[hex]?[mat]?
          data.push 16 * v.t + v.s, v.r, v.g, v.b, v.a
          rcolors[hex][mat] = (data.length - 7) / 5
          throw new Error "To many colors for Troxel2 palette" unless (data.length - 7) / 5 < 32768
      data[5] = (data.length - 7) // 1280
      short = data[5] == 0
      data[6] = (data.length - 7) / 5 % 256
      while i < vox.length
        r = 1 # repeat
        (if equal vox[i + r - 1], vox[i + r], i + r then r++ else break) while r < 129
        data.push 126 + r if r > 1 # 1xxxxxxx wheree x^7 = r - 2
        if vox[i]?
          index = rcolors[ vox[i].b + 256 * vox[i].g + 65536 * vox[i].r ][ vox[i].a + 256 * vox[i].t + 2048 * vox[i].s ]
          if short
            data.push index
          else
            data.push index // 256, index % 256
        else
          data.push 0 # empty
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
