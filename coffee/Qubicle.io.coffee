# ToDo: Handle negative matrix offsets

# http://www.minddesk.com/wiki/index.php?title=Qubicle_Constructor_1:Data_Exchange_With_Qubicle_Binary
class QubicleIO extends IO
  constructor: (files, callback) ->
    return if super(files)
    @voxels = []
    @x = @y = @z = -1
    @loadingState = 0
    fr = new FileReader()
    fr.onloadend = =>
      @readFile fr.result, 0
      if files.a?
        fra = new FileReader()
        fra.onloadend = =>
          @readFile fra.result, 1
          callback() if @loadingState++ == 2
        console.log "reading alpha file with name: #{files.a.name}"
        fra.readAsArrayBuffer files.a
      else
        @loadingState++
      if files.t?
        frt = new FileReader()
        frt.onloadend = =>
          @readFile frt.result, 2
          callback() if @loadingState++ == 2
        console.log "reading type file with name: #{files.t.name}"
        frt.readAsArrayBuffer files.t
      else
        @loadingState++
      if files.s?
        frs = new FileReader()
        frs.onloadend = =>
          @readFile frs.result, 3
          callback() if @loadingState++ == 2
        console.log "reading specular file with name: #{files.s.name}"
        frs.readAsArrayBuffer files.s
      else
        @loadingState++
      callback() if @loadingState == 3
    console.log "reading file with name: #{files.m.name}"
    fr.readAsArrayBuffer files.m

  readFile: (ab, type) ->
    console.log "file.byteLength: #{ab.byteLength}"
    [version, colorFormat, zOriantation, compression, visabilityMask, matrixCount] = new Uint32Array ab.slice 0, 24
    console.log "version: #{version} (expected 257 = 1.1.0.0 = current version)"
    console.warn "Expected version 257 but found version: #{version} (May result in errors)" unless version == 257
    console.log "color format: #{colorFormat} (0 for RGBA (recommended) or 1 for BGRA)"
    console.log "z-axis oriantation: #{zOriantation} (0 for left (recommended), 1 for right handed)"
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
      dx = dy = dz = 0 if matrixCount == 1
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
              @addValues type, ix + dx, iy + dy, z, iz, dz, zOriantation, data[ia], data[ia+1], data[ia+2], colorFormat if data[ia+3] > 0
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
              count = new Uint32Array(new Uint8Array([data[ia], data[ia+1], data[ia+2], data[ia+3]]).buffer)[0]
              console.log "high voxel repeat count: #{count}" if count > 255
              if data[ia+7] > 0 # if vox exists
                for j in [0...count] by 1
                  ix = index % x
                  iy = index // x
                  index++
                  @addValues type, ix + dx, iy + dy, z, iz, dz, zOriantation, data[ia+4], data[ia+5], data[ia+6], colorFormat
              else
                index += count
              ia += 8
            else
              ix = index % x
              iy = index // x
              index++
              @addValues type, ix + dx, iy + dy, z, iz, dz, zOriantation, data[ia-4], data[ia-3], data[ia-2], colorFormat if data[ia-1] > 0
        matrixBegin += 25 + nameLen + ia
    console.log "voxels:"
    console.log @voxels
    console.warn console.log "There shouldn't be any bytes left" unless matrixBegin == ab.byteLength

  addValues: (type, x, y, z, iz, dz, zOriantation, r, g, b, colorFormat) ->
    z = (if zOriantation == 0 then iz else z - iz - 1) + dz
    [r, b] = [b, r] if colorFormat == 1
    switch type
      when 0 then @addColorValues x, y, z, r, g, b
      when 1 then @addAlphaValues x, y, z, r, g, b
      when 2 then @addTypeValues x, y, z, r, g, b
      when 3 then @addSpecularValues x, y, z, r, g, b

  addColorValues: (x, y, z, r, g, b) ->
    @voxels[z] = [] unless @voxels[z]?
    @voxels[z][y] = [] unless @voxels[z][y]?
    @voxels[z][y][x] = {r: r, g: g, b: b, a: 255, t: 0, s: 0}

  addAlphaValues: (x, y, z, r, g, b) ->
    return console.warn "Ignoring alpha voxel because of non existing color voxel at the same position" unless @voxels[z]?[y]?[x]?
    if r == g and g == b
      return @voxels[z][y][x].a = switch r
        when  16 then 255 # Solid
        when  48 then 240 #   |
        when  80 then 208 #   |
        when 112 then 176 #   |
        when 144 then 144 #   |
        when 176 then 112 #   |
        when 208 then  80 #   |
        when 240 then  48 #   V
        when 255 then  16 # Very Transparent
        else
          console.warn "invalid alpha value: r, g and b are not equal, falling back to fully opaque"
          255
    return @voxels[z][y][x].a = 255 if r == b == 255 and g == 0 # attachment point
    console.warn "invalid alpha value: r, g and b are not equal, falling back to fully opaque"
    @voxels[z][y][x].a = 255

  addTypeValues: (x, y, z, r, g, b) ->
    return console.warn "Ignoring type voxel because of non existing color voxel at the same position" unless @voxels[z]?[y]?[x]?
    return @voxels[z][y][x].t = 0 if r == 255 and g == 255 and b == 255 # solid
    return @voxels[z][y][x].t = 1 if r == 128 and g == 128 and b == 128 # glass
    return @voxels[z][y][x].t = 2 if r ==  64 and g ==  64 and b ==  64 # tiled glass
    return @voxels[z][y][x].t = 3 if r == 255 and g ==   0 and b ==   0 # glowing solid
    return @voxels[z][y][x].t = 4 if r == 255 and g == 255 and b ==   0 # glowing glass
    return @voxels[z][y][x].t = 7 if r == 255 and g ==   0 and b == 255 # attachment point
    console.warn "invalid type value (r: #{r}, g: #{g}, b: #{b}), falling back to solid"
    @voxels[z][y][x].t = 0

  addSpecularValues: (x, y, z, r, g, b) ->
    return console.warn "Ignoring specular voxel because of non existing color voxel at the same position" unless @voxels[z]?[y]?[x]?
    return @voxels[z][y][x].s = 0 if r == 128 and g ==   0 and b ==   0 # rough
    return @voxels[z][y][x].s = 1 if r ==   0 and g == 128 and b ==   0 # metal
    return @voxels[z][y][x].s = 2 if r ==   0 and g ==   0 and b == 128 # water
    return @voxels[z][y][x].s = 3 if r == 128 and g == 128 and b ==   0 # iridescent
    return @voxels[z][y][x].s = 7 if r == 255 and g ==   0 and b == 255 # attachment point
    console.warn "invalid specular value (r: #{r}, g: #{g}, b: #{b}), falling back to rough"
    @voxels[z][y][x].s = 0

  export: (comp) ->
    data = [
      1, 1, 0, 0 # version: 1.1.0.0 (current)
      0, 0, 0, 0 # color format: rgba
      0, 0, 0, 0 # z-axis oriantation: left handed
      +comp, 0, 0, 0 # compression: no (1, 0, 0, 0 for compressed)
      0, 0, 0, 0 # visability mask: no partially visibility
      1, 0, 0, 0 # matrix count: 1
      5          # name length: 5
      77, 157, 144, 145, 154 # name: Model
      @x, 0, 0, 0 # width
      @y, 0, 0, 0 # height
      @z, 0, 0, 0 # depth
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 # no position offsets
    ]
    data_a = data.slice 0
    data_t = data.slice 0
    data_s = data.slice 0

    exportValues = (vox) ->
      if vox?
        data = data.concat [vox.r, vox.g, vox.b, 255]
        data_a = data_a.concat switch
          when vox.t == 7 and vox.s == 7 then [255, 0, 255, 255] # attachment point
          when vox.a == 255 then [ 16,  16,  16, 255] # Solid
          when vox.a  > 224 then [ 48,  48,  48, 255] #   |
          when vox.a  > 192 then [ 80,  80,  80, 255] #   |
          when vox.a  > 160 then [112, 112, 112 ,255] #   |
          when vox.a  > 128 then [144, 144, 144 ,255] #   |
          when vox.a  >  96 then [176, 176, 176 ,255] #   |
          when vox.a  >  64 then [208, 208, 208 ,255] #   |
          when vox.a  >  32 then [240, 240, 240 ,255] #   V
          else                   [255, 255, 255, 255] # Very Transparent
        data_t = data_t.concat switch vox.t
          when 0 then [255, 255, 255, 255] # solid (default)
          when 1 then [128, 128, 128, 255] # glass
          when 2 then [ 64,  64,  64, 255] # tiled glass
          when 3 then [255,   0,   0, 255] # glowing solid
          when 4 then [255, 255,   0, 255] # glowing glass
          when 7 then [255,   0, 255, 255] # attachment point
          else        [255, 255, 255, 255] # fallback to solid (default)
        data_s = data_s.concat switch vox.s
          when 0 then [128,   0,   0, 255] # rough (default)
          when 1 then [  0, 128,   0, 255] # metal
          when 2 then [  0,   0, 128, 255] # water
          when 3 then [128, 128,   0, 255] # iridescent
          when 7 then [255,   0, 255, 255] # attachment point
          else        [128,   0,   0, 255] # fallback to rough (default)
      else
        data   = data.concat   [0, 0, 0, 0]
        data_a = data_a.concat [0, 0, 0, 0]
        data_t = data_t.concat [0, 0, 0, 0]
        data_s = data_s.concat [0, 0, 0, 0]

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
              data   = data.concat   [2, 0, 0, 0, c1, c2, c3, c4] # CODEFLAG + count
              data_a = data_a.concat [2, 0, 0, 0, c1, c2, c3, c4]
              data_t = data_t.concat [2, 0, 0, 0, c1, c2, c3, c4]
              data_s = data_s.concat [2, 0, 0, 0, c1, c2, c3, c4]
            exportValues vox[i] # push data
            i += r
        data   = data.concat   [6, 0, 0, 0] # NEXTSLICEFLAG
        data_a = data_a.concat [6, 0, 0, 0]
        data_t = data_t.concat [6, 0, 0, 0]
        data_s = data_s.concat [6, 0, 0, 0]
    else
      exportValues @voxels[z]?[y]?[x] for x in [0...@x] by 1 for y in [0...@y] by 1 for z in [0...@z] by 1
    console.log "export Qubicle:"
    console.log data
    URL.createObjectURL new Blob [new Uint8Array ta], type: 'application/octet-binary' for ta in [data, data_a, data_t, data_s]

if typeof module == 'object' then module.exports = QubicleIO else window.QubicleIO = QubicleIO
