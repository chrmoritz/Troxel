# http://www.minddesk.com/wiki/index.php?title=Qubicle_Constructor_1:Data_Exchange_With_Qubicle_Binary
'use strict'
class QubicleIO extends IO
  constructor: (files, callback) ->
    return if super(files)
    @voxels = []
    @x = @y = @z = -1
    @warn = []
    @loadingState = 0
    fr = new FileReader()
    fr.onloadend = =>
      APpos = @readFile fr.result, 0
      if files.a?
        fra = new FileReader()
        fra.onloadend = =>
          @readFile fra.result, 1
          if @loadingState++ == 2
            @mirrorZ() if @zOriantation == 0
            callback(APpos)
        console.log "reading alpha file with name: #{files.a.name}"
        fra.readAsArrayBuffer files.a
      else
        @loadingState++
      if files.t?
        frt = new FileReader()
        frt.onloadend = =>
          @readFile frt.result, 2
          if @loadingState++ == 2
            @mirrorZ() if @zOriantation == 0
            callback(APpos)
        console.log "reading type file with name: #{files.t.name}"
        frt.readAsArrayBuffer files.t
      else
        @loadingState++
      if files.s?
        frs = new FileReader()
        frs.onloadend = =>
          @readFile frs.result, 3
          if @loadingState++ == 2
            @mirrorZ() if @zOriantation == 0
            callback(APpos)
        console.log "reading specular file with name: #{files.s.name}"
        frs.readAsArrayBuffer files.s
      else
        @loadingState++
      if @loadingState == 3
        @mirrorZ() if @zOriantation == 0
        callback(APpos)
    console.log "reading file with name: #{files.m.name}"
    fr.readAsArrayBuffer files.m

  readFile: (ab, type) ->
    console.log "file.byteLength: #{ab.byteLength}"
    [version, colorFormat, zOriantation, compression, visabilityMask, matrixCount] = new Uint32Array ab.slice 0, 24
    console.log "version: #{version} (expected 257 = 1.1.0.0 = current version)"
    console.warn "Expected version 257 but found version: #{version} (May result in errors)" unless version == 257
    console.log "color format: #{colorFormat} (0 for RGBA (recommended) or 1 for BGRA)"
    console.log "z-axis oriantation: #{zOriantation} (0 for left, 1 for right handed (recommended))"
    @zOriantation = zOriantation if type == 0
    console.log "compression: #{compression} (0 for uncompressed, 1 for compressed with run length encoding (RLE))"
    console.log "visability mask: #{visabilityMask} (should be 0 for encoded in A value, no partially visability)"
    console.warn "partially visability not supported and will be ignored / handled as full visibility" unless visabilityMask == 0
    console.log "matrix count:  #{matrixCount}"
    console.warn "matrices will be merged into one matrix with regard to their offsets" if matrixCount > 1
    dx_offset = dy_offset = dz_offset = 0
    if matrixCount > 1 # calculate matrix position offset to move all matices into positive positions
      mb = 24
      for i in [1..matrixCount] by 1
        [nameLen] = new Uint8Array ab.slice mb, mb + 1
        [x, y, z] = new Uint32Array ab.slice mb + 1 + nameLen, mb + 13 + nameLen
        [dx, dy, dz] = new Int32Array ab.slice mb + 13 + nameLen, mb + 25 + nameLen
        dx_offset = Math.min dx_offset, dx
        dy_offset = Math.min dy_offset, dy
        dz_offset = Math.min dz_offset, dz
        if compression == 0
          mb += 25 + nameLen + 4*x*y*z
        else
          ia = 0
          data = new Uint8Array ab.slice mb + 25 + nameLen
          for iz in [0...z] by 1
            loop
              ia += 4
              break if data[ia-4] == 6 and data[ia-3] == 0 and data[ia-2] == 0 and data[ia-1] == 0 # NEXTSLICEFLAG
              ia += 8 if data[ia-4] == 2 and data[ia-3] == 0 and data[ia-2] == 0 and data[ia-1] == 0 # CODEFLAG
          mb += 25 + nameLen + ia
    matrixBegin = 24
    for i in [1..matrixCount] by 1
      console.log "------------------------ Matrix: #{i} ------------------------"
      [nameLen] = new Uint8Array ab.slice matrixBegin, matrixBegin + 1
      name = (String.fromCharCode char for char in new Uint8Array ab.slice matrixBegin + 1, matrixBegin + 1 + nameLen).join ''
      console.log "reading #{i}. matrix with name: #{name}"
      [x, y, z] = new Uint32Array ab.slice matrixBegin + 1 + nameLen, matrixBegin + 13 + nameLen
      console.log "dimensions: width: #{x} height: #{y} depth: #{z}"
      [dx, dy, dz] = new Int32Array ab.slice matrixBegin + 13 + nameLen, matrixBegin + 25 + nameLen
      console.log "position: dx : #{dx} dy: #{dy} dz: #{dz} (ignored if only 1 matrix)"
      if matrixCount == 1
        if type == 0 and dx <= 0 and dy <= 0 and dz <= 0 and (dx < 0 or dy < 0 or dz < 0)
          APpos = [-dx, -dy, -dz]
        dx = dy = dz = 0
      if matrixCount > 1
        dx -= dx_offset
        dy -= dy_offset
        dz -= dz_offset
      console.log "position result: dx : #{dx} dy: #{dy} dz: #{dz}"
      if type == 0
        @x = Math.max @x, x + dx
        @y = Math.max @y, y + dy
        @z = Math.max @z, z + dz
      if compression == 0
        data = new Uint8Array ab.slice matrixBegin + 25 + nameLen, matrixBegin + 25 + nameLen + 4*x*y*z
        for iz in [0...z] by 1
          for iy in [0...y] by 1
            for ix in [0...x] by 1
              ia = 4 * (iz*y*x + iy*x + ix)
              @addValues type, ix + dx, iy + dy, iz + dz, data[ia], data[ia+1], data[ia+2], colorFormat if data[ia+3] > 0
        matrixBegin += 25 + nameLen + 4*x*y*z
      else
        data = new Uint8Array ab.slice matrixBegin + 25 + nameLen
        ia = 0
        for iz in [0...z] by 1
          index = 0
          loop
            ia += 4
            break if data[ia-4] == 6 and data[ia-3] == 0 and data[ia-2] == 0 and data[ia-1] == 0 # NEXTSLICEFLAG
            if data[ia-4] == 2 and data[ia-3] == 0 and data[ia-2] == 0 and data[ia-1] == 0 # CODEFLAG
              count = data[ia] + (data[ia+1]<<8) + (data[ia+2]<<16) + (data[ia+3]<<24)
              if data[ia+7] > 0 # if vox exists
                for j in [0...count] by 1
                  ix = index % x
                  iy = Math.floor index / x
                  index++
                  @addValues type, ix + dx, iy + dy, iz + dz, data[ia+4], data[ia+5], data[ia+6], colorFormat
              else
                index += count
              ia += 8
            else
              ix = index % x
              iy = Math.floor index / x
              index++
              @addValues type, ix + dx, iy + dy, iz + dz, data[ia-4], data[ia-3], data[ia-2], colorFormat if data[ia-1] > 0
        matrixBegin += 25 + nameLen + ia
    console.log "voxels:"
    console.log @voxels
    console.warn "There shouldn't be any bytes left" unless matrixBegin == ab.byteLength
    return APpos

  addValues: (type, x, y, z, r, g, b, colorFormat) ->
    [r, b] = [b, r] if colorFormat == 1
    switch type
      when 0 then @addColorValues x, y, z, r, g, b
      when 1 then @addAlphaValues x, y, z, r, g, b
      when 2 then @addTypeValues x, y, z, r, g, b
      when 3 then @addSpecularValues x, y, z, r, g, b

  addColorValues: (x, y, z, r, g, b) ->
    @voxels[z] = [] unless @voxels[z]?
    @voxels[z][y] = [] unless @voxels[z][y]?
    return @voxels[z][y][x] = {r: 255, g: 0, b: 255, a: 250, t: 7, s: 7} if r == b == 255 and g == 0 # attachment point
    @voxels[z][y][x] = {r: r, g: g, b: b, a: 255, t: 0, s: 0}

  addAlphaValues: (x, y, z, r, g, b) ->
    unless @voxels[z]?[y]?[x]?
      @warn.push "(x: #{x}, y: #{y}, z: #{z}): Ignoring alpha voxel because of non existing color voxel at the same position"
      return console.warn "(x: #{x}, y: #{y}, z: #{z}): Ignoring alpha voxel because of non existing color voxel at the same position"
    if r == g and g == b
      return @voxels[z][y][x].a = r if r in [16, 48, 80, 112, 144, 176, 208, 240, 255]
      console.warn "(x: #{x}, y: #{y}, z: #{z}): Invalid alpha value #{r}: falling back to 122"
      @warn.push "(x: #{x}, y: #{y}, z: #{z}): Invalid alpha value #{r}: falling back to 122"
      return @voxels[z][y][x].a = 112
    return @voxels[z][y][x].a = 250 if r == b == 255 and g == 0 # attachment point
    console.warn "(x: #{x}, y: #{y}, z: #{z}): Invalid alpha value (#{r}, #{g}, #{b}): r, g and b are not equal, falling back to 112"
    @warn.push "(x: #{x}, y: #{y}, z: #{z}): Invalid alpha value (#{r}, #{g}, #{b}): r, g and b are not equal, falling back to 112"
    @voxels[z][y][x].a = 112

  addTypeValues: (x, y, z, r, g, b) ->
    unless @voxels[z]?[y]?[x]?
      @warn.push "(x: #{x}, y: #{y}, z: #{z}): Ignoring type voxel because of non existing color voxel at the same position"
      return console.warn "(x: #{x}, y: #{y}, z: #{z}): Ignoring type voxel because of non existing color voxel at the same position"
    return @voxels[z][y][x].t = 0 if r == 255 and g == 255 and b == 255 # solid
    return @voxels[z][y][x].t = 1 if r == 128 and g == 128 and b == 128 # glass
    return @voxels[z][y][x].t = 2 if r ==  64 and g ==  64 and b ==  64 # tiled glass
    return @voxels[z][y][x].t = 3 if r == 255 and g ==   0 and b ==   0 # glowing solid
    return @voxels[z][y][x].t = 4 if r == 255 and g == 255 and b ==   0 # glowing glass
    return @voxels[z][y][x].t = 7 if r == 255 and g ==   0 and b == 255 # attachment point
    console.warn "(x: #{x}, y: #{y}, z: #{z}): Invalid type value (#{r}, #{g}, #{b}), falling back to solid"
    @warn.push "(x: #{x}, y: #{y}, z: #{z}): Invalid type value (#{r}, #{g}, #{b}), falling back to solid"
    @voxels[z][y][x].t = 0

  addSpecularValues: (x, y, z, r, g, b) ->
    unless @voxels[z]?[y]?[x]?
      @warn.push "(x: #{x}, y: #{y}, z: #{z}): Ignoring specular voxel because of non existing color voxel at the same position"
      return console.warn "(x: #{x}, y: #{y}, z: #{z}): Ignoring specular voxel because of non existing color voxel at the same position"
    return @voxels[z][y][x].s = 0 if r == 128 and g ==   0 and b ==   0 # rough
    return @voxels[z][y][x].s = 1 if r ==   0 and g == 128 and b ==   0 # metal
    return @voxels[z][y][x].s = 2 if r ==   0 and g ==   0 and b == 128 # water
    return @voxels[z][y][x].s = 3 if r == 128 and g == 128 and b ==   0 # iridescent
    return @voxels[z][y][x].s = 4 if r == 128 and g ==   0 and b == 128 # waxy
    return @voxels[z][y][x].s = 7 if r == 255 and g ==   0 and b == 255 # attachment point
    unless r == g == b == 255 # Trove relies on this fallback often
      console.warn "(x: #{x}, y: #{y}, z: #{z}): Invalid specular value (#{r}, #{g}, #{b}), falling back to rough"
      @warn.push "(x: #{x}, y: #{y}, z: #{z}): Invalid specular value (#{r}, #{g}, #{b}), falling back to rough"
    @voxels[z][y][x].s = 0

  export: (comp) ->
    data = [
      1, 1, 0, 0 # version: 1.1.0.0 (current)
      0, 0, 0, 0 # color format: rgba
      1, 0, 0, 0 # z-axis oriantation: right handed
      +comp, 0, 0, 0 # compression: no (1, 0, 0, 0 for compressed)
      0, 0, 0, 0 # visability mask: no partially visibility
      1, 0, 0, 0 # matrix count: 1
      5          # name length: 5
      77, 111, 100, 101, 108 # name: Model
    ]

    if @x < 256
      data.push @x, 0, 0, 0 # width
    else
      Array::push.apply data, new Uint8Array(new Uint32Array([@x]).buffer)
    if @y < 256
      data.push @y, 0, 0, 0 # height
    else
      Array::push.apply data, new Uint8Array(new Uint32Array([@y]).buffer)
    if @z < 256
      data.push @z, 0, 0, 0 # depth
    else
      Array::push.apply data, new Uint8Array(new Uint32Array([@z]).buffer)
    data.push 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 # no position offsets

    data_a = data.slice 0
    data_t = data.slice 0
    data_s = data.slice 0

    exportValues = (vox) ->
      if vox?
        data.push vox.r, vox.g, vox.b, 255
        switch vox.a
          when 250 then data_a.push 255,   0, 255, 255 # attachment point
          when 255 then data_a.push 255, 255, 255, 255 # solid (type map set to non transparent type)
          when 240 then data_a.push 240, 240, 240, 255 # Nearly Solid
          when 208 then data_a.push 208, 208, 208, 255 #      |
          when 176 then data_a.push 176, 176, 176, 255 #      |
          when 144 then data_a.push 144, 144, 144, 255 #      |
          when 112 then data_a.push 112, 112, 112, 255 #      |
          when  80 then data_a.push  80,  80,  80, 255 #      |
          when  48 then data_a.push  48,  48,  48, 255 #      V
          when  16 then data_a.push  16,  16,  16, 255 # Very Transparent
          else          data_a.push 112, 112, 112, 255 # fallback
        switch vox.t
          when 0 then data_t.push 255, 255, 255, 255 # solid (default)
          when 1 then data_t.push 128, 128, 128, 255 # glass
          when 2 then data_t.push  64,  64,  64, 255 # tiled glass
          when 3 then data_t.push 255,   0,   0, 255 # glowing solid
          when 4 then data_t.push 255, 255,   0, 255 # glowing glass
          when 7 then data_t.push 255,   0, 255, 255 # attachment point
          else        data_t.push 255, 255, 255, 255 # fallback to solid (default)
        switch vox.s
          when 0 then data_s.push 128,   0,   0, 255 # rough (default)
          when 1 then data_s.push   0, 128,   0, 255 # metal
          when 2 then data_s.push   0,   0, 128, 255 # water
          when 3 then data_s.push 128, 128,   0, 255 # iridescent
          when 4 then data_s.push 128,   0, 128, 255 # waxy
          when 7 then data_s.push 255,   0, 255, 255 # attachment point
          else        data_s.push 128,   0,   0, 255 # fallback to rough (default)
      else
        data.push   0, 0, 0, 0
        data_a.push 0, 0, 0, 0
        data_t.push 0, 0, 0, 0
        data_s.push 0, 0, 0, 0

    equal = (a, b) ->
      return true if !a? and !b?
      return false if !a? or !b?
      return false for i in ['r', 'g', 'b', 'a', 't', 's'] when a[i] != b[i]
      return true

    if comp # compressed
      for z in [0...@z] by 1
        if @voxels[z]? # else if plane completly empty just push NEXTSLICEFLAG
          vox = [] # 1d array of current plane
          lastVox = -1 # last non empty Voxel at index
          for y in [0...@y] by 1
            for x in [0...@x] by 1
              vox.push @voxels[z][y]?[x]
              lastVox = vox.length - 1 if @voxels[z][y]?[x]?
          i = 0
          while i <= lastVox # loop through vox until lastVox (included)
            r = 1 # repeat
            (if equal vox[i + r - 1], vox[i + r] then r++ else break) while i + r <= lastVox
            if r > 1
              [c1, c2, c3, c4] = new Uint8Array new Uint32Array([r]).buffer
              data.push   2, 0, 0, 0, c1, c2, c3, c4 # CODEFLAG + count
              data_a.push 2, 0, 0, 0, c1, c2, c3, c4
              data_t.push 2, 0, 0, 0, c1, c2, c3, c4
              data_s.push 2, 0, 0, 0, c1, c2, c3, c4
            exportValues vox[i] # push data
            i += r
        data.push   6, 0, 0, 0 # NEXTSLICEFLAG
        data_a.push 6, 0, 0, 0
        data_t.push 6, 0, 0, 0
        data_s.push 6, 0, 0, 0
    else
      exportValues @voxels[z]?[y]?[x] for x in [0...@x] by 1 for y in [0...@y] by 1 for z in [0...@z] by 1
    console.log "export Qubicle:"
    console.log data
    URL.createObjectURL new Blob [new Uint8Array ta], type: 'application/octet-binary' for ta in [data, data_a, data_t, data_s]

if typeof module == 'object' then module.exports = QubicleIO else window.QubicleIO = QubicleIO
