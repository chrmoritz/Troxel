# https://github.com/grking/zoxel/blob/develop/src/plugins/io_zoxel.py
'use strict'
class ZoxelIO extends require('./IO.coffee!')
  constructor: (file, callback) ->
    return if super(file)
    @voxels = []
    fr = new FileReader()
    fr.onloadend = =>
      data = JSON.parse fr.result
      {"creator": c, "width": @x, "height": @y, "depth": @z, "version": v, "frames": frames} = data
      console.log "creator: #{x}"
      console.log "version: #{v} (expected 1)"
      console.log "frames: #{frames} (expected 1)"
      console.log "dimensions: width : #{@x} height: #{@y} depth: #{@z}"
      console.log "frame data:"
      for f in [1..frames] by 1
        console.log data["frame#{f}"]
        for [x, y, z, c] in data["frame#{f}"]
          z = @z - z - 1
          x = @x - x - 1
          @voxels[z] = [] unless @voxels[z]?
          @voxels[z][y] = [] unless @voxels[z][y]?
          @voxels[z][y][x] = {r: (c & 0xff000000) >>> 24, g: (c & 0x00ff0000) >>> 16, b: (c & 0x0000ff00) >>> 8, a: 255, t: 0, s: 0}
          if @voxels[z][y][x].r == 255 and @voxels[z][y][x].g == 0 and @voxels[z][y][x].b == 255
            @voxels[z][y][x] = {r: 255, g: 0, b: 255, a: 250, t: 7, s: 7} # attachment point
      console.log "voxels:"
      console.log @voxels
      callback()
    console.log "reading file with name: #{file.name}"
    fr.readAsText file

  export: ->
    frame = []
    frame.push [@x - ix - 1, iy, @z - iz - 1, ((x.r << 24) | (x.g << 16) | (x.b << 8) | 255) >>> 0] for x, ix in y when x? for y, iy in z when y? for z, iz in @voxels when z?
    json = {creator: "Troxel", width: @x, height: @y, depth: @z, version: 1, frames: 1, frame1: frame}
    console.log "Zoxel export:"
    console.log json
    JSON.stringify json

module.exports = ZoxelIO
