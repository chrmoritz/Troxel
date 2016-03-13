class JsonIO extends require('./IO.coffee')
  constructor: (json) ->
    return if super(json)
    {x: @x, y: @y, z: @z, voxels: @voxels} = JSON.parse json

  export: (pretty) ->
    JSON.stringify {x: @x, y: @y, z: @z, voxels: @voxels}, null, if pretty then '    ' else ''

module.exports = JsonIO
