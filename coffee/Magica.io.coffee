# http://voxel.codeplex.com/wikipage?title=VOX%20Format&referringTitle=MagicaVoxel%20Editor
class MagicaIO extends IO
  constructor: (file, callback) ->
    return if super(file)
    fr = new FileReader()
    fr.onloadend = =>
      ab = fr.result
      meta = (String.fromCharCode char for char in new Uint8Array ab.slice 0, 4).join ''
      console.log "meta: #{meta} (expected VOX )"
      throw new Error "Expected Magica Voxel header not found" unless meta == 'VOX '
      [version] = new Uint32Array ab.slice 4, 8
      console.log "version: #{version} (expected 150)"
      console.warn "Expected version 150 but found version: #{version} (May result in errors)" unless version == 150
      mainChunkId = (String.fromCharCode char for char in new Uint8Array ab.slice 8, 12).join ''
      console.log "mainChunkId: #{mainChunkId} (expected MAIN)"
      throw new Error "Didn't found main Chunk as expected" unless mainChunkId == 'MAIN'
      [mainChunkSize, mainChunkChildSize] = new Uint32Array ab.slice 12, 20
      console.log "mainChunkSize: #{mainChunkSize} (expected 0)"
      console.log "mainChunkChildSize: #{mainChunkChildSize}"
      console.warn console.log "There shouldn't be any bytes left" unless 20 + mainChunkChildSize == ab.byteLength
      # search for SIZE, XYZI (voxel) and optional RGBA (palette) chunk
      chunkPointer = 20 + mainChunkSize
      sizeBegin = sizeEnd = voxelBegin = voxelEnd = paletteBegin = paletteLength = -1
      while chunkPointer < 20 + mainChunkSize + mainChunkChildSize
        chunkId = (String.fromCharCode char for char in new Uint8Array ab.slice chunkPointer, chunkPointer + 4).join ''
        console.log new Uint8Array ab.slice chunkPointer, chunkPointer + 12##
        [chunkSize, chunkChildSize] = new Uint32Array ab.slice chunkPointer + 4, chunkPointer + 12
        console.log "found child chunk: #{chunkId} with begin: #{chunkPointer + 12}, size: #{chunkSize} and childSize: #{chunkChildSize} (expected 0)"
        switch chunkId
          when "SIZE"
            console.warn "invalid length of size chunk" unless chunkSize == 12
            sizeBegin = chunkPointer + 12
            sizeEnd = sizeBegin + chunkSize
          when "XYZI"
            voxelBegin = chunkPointer + 12
            voxelEnd = voxelBegin + chunkSize
          when "RGBA"
            paletteBegin = chunkPointer + 12
            console.warn "invalid length of palette chunk" unless chunkSize == 1024
            paletteLength =  chunkSize
        chunkPointer += 12 + chunkSize + chunkChildSize
      throw new Error "missing chunks" if sizeBegin == -1 or sizeEnd == -1 or voxelBegin == -1 or voxelEnd == -1
      # read size chunk
      [@x, @y, @z] = new Uint32Array ab.slice sizeBegin, sizeEnd
      console.log "dimensions: width: #{@x} height: #{@y} depth: #{@z}"
      # read palette chunk
      palette = []
      if paletteBegin == -1 or paletteLength == -1
        palette = [ # default palette
          {'r':255, 'g':255, 'b':255, 'a':112, 't':0, 's':0}, {'r':255, 'g':255, 'b':204, 'a':112, 't':0, 's':0}, {'r':255, 'g':255, 'b':153, 'a':112, 't':0, 's':0},
          {'r':255, 'g':255, 'b':102, 'a':112, 't':0, 's':0}, {'r':255, 'g':255, 'b': 51, 'a':112, 't':0, 's':0}, {'r':255, 'g':255, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':255, 'g':204, 'b':255, 'a':112, 't':0, 's':0}, {'r':255, 'g':204, 'b':204, 'a':112, 't':0, 's':0}, {'r':255, 'g':204, 'b':153, 'a':112, 't':0, 's':0},
          {'r':255, 'g':204, 'b':102, 'a':112, 't':0, 's':0}, {'r':255, 'g':204, 'b': 51, 'a':112, 't':0, 's':0}, {'r':255, 'g':204, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':255, 'g':153, 'b':255, 'a':112, 't':0, 's':0}, {'r':255, 'g':153, 'b':204, 'a':112, 't':0, 's':0}, {'r':255, 'g':153, 'b':153, 'a':112, 't':0, 's':0},
          {'r':255, 'g':153, 'b':102, 'a':112, 't':0, 's':0}, {'r':255, 'g':153, 'b': 51, 'a':112, 't':0, 's':0}, {'r':255, 'g':153, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':255, 'g':102, 'b':255, 'a':112, 't':0, 's':0}, {'r':255, 'g':102, 'b':204, 'a':112, 't':0, 's':0}, {'r':255, 'g':102, 'b':153, 'a':112, 't':0, 's':0},
          {'r':255, 'g':102, 'b':102, 'a':112, 't':0, 's':0}, {'r':255, 'g':102, 'b': 51, 'a':112, 't':0, 's':0}, {'r':255, 'g':102, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':255, 'g': 51, 'b':255, 'a':112, 't':0, 's':0}, {'r':255, 'g': 51, 'b':204, 'a':112, 't':0, 's':0}, {'r':255, 'g': 51, 'b':153, 'a':112, 't':0, 's':0},
          {'r':255, 'g': 51, 'b':102, 'a':112, 't':0, 's':0}, {'r':255, 'g': 51, 'b': 51, 'a':112, 't':0, 's':0}, {'r':255, 'g': 51, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':255, 'g':  0, 'b':255, 'a':112, 't':0, 's':0}, {'r':255, 'g':  0, 'b':204, 'a':112, 't':0, 's':0}, {'r':255, 'g':  0, 'b':153, 'a':112, 't':0, 's':0},
          {'r':255, 'g':  0, 'b':102, 'a':112, 't':0, 's':0}, {'r':255, 'g':  0, 'b': 51, 'a':112, 't':0, 's':0}, {'r':255, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':204, 'g':255, 'b':255, 'a':112, 't':0, 's':0}, {'r':204, 'g':255, 'b':204, 'a':112, 't':0, 's':0}, {'r':204, 'g':255, 'b':153, 'a':112, 't':0, 's':0},
          {'r':204, 'g':255, 'b':102, 'a':112, 't':0, 's':0}, {'r':204, 'g':255, 'b': 51, 'a':112, 't':0, 's':0}, {'r':204, 'g':255, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':204, 'g':204, 'b':255, 'a':112, 't':0, 's':0}, {'r':204, 'g':204, 'b':204, 'a':112, 't':0, 's':0}, {'r':204, 'g':204, 'b':153, 'a':112, 't':0, 's':0},
          {'r':204, 'g':204, 'b':102, 'a':112, 't':0, 's':0}, {'r':204, 'g':204, 'b': 51, 'a':112, 't':0, 's':0}, {'r':204, 'g':204, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':204, 'g':153, 'b':255, 'a':112, 't':0, 's':0}, {'r':204, 'g':153, 'b':204, 'a':112, 't':0, 's':0}, {'r':204, 'g':153, 'b':153, 'a':112, 't':0, 's':0},
          {'r':204, 'g':153, 'b':102, 'a':112, 't':0, 's':0}, {'r':204, 'g':153, 'b': 51, 'a':112, 't':0, 's':0}, {'r':204, 'g':153, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':204, 'g':102, 'b':255, 'a':112, 't':0, 's':0}, {'r':204, 'g':102, 'b':204, 'a':112, 't':0, 's':0}, {'r':204, 'g':102, 'b':153, 'a':112, 't':0, 's':0},
          {'r':204, 'g':102, 'b':102, 'a':112, 't':0, 's':0}, {'r':204, 'g':102, 'b': 51, 'a':112, 't':0, 's':0}, {'r':204, 'g':102, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':204, 'g': 51, 'b':255, 'a':112, 't':0, 's':0}, {'r':204, 'g': 51, 'b':204, 'a':112, 't':0, 's':0}, {'r':204, 'g': 51, 'b':153, 'a':112, 't':0, 's':0},
          {'r':204, 'g': 51, 'b':102, 'a':112, 't':0, 's':0}, {'r':204, 'g': 51, 'b': 51, 'a':112, 't':0, 's':0}, {'r':204, 'g': 51, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':204, 'g':  0, 'b':255, 'a':112, 't':0, 's':0}, {'r':204, 'g':  0, 'b':204, 'a':112, 't':0, 's':0}, {'r':204, 'g':  0, 'b':153, 'a':112, 't':0, 's':0},
          {'r':204, 'g':  0, 'b':102, 'a':112, 't':0, 's':0}, {'r':204, 'g':  0, 'b': 51, 'a':112, 't':0, 's':0}, {'r':204, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':153, 'g':255, 'b':255, 'a':112, 't':0, 's':0}, {'r':153, 'g':255, 'b':204, 'a':112, 't':0, 's':0}, {'r':153, 'g':255, 'b':153, 'a':112, 't':0, 's':0},
          {'r':153, 'g':255, 'b':102, 'a':112, 't':0, 's':0}, {'r':153, 'g':255, 'b': 51, 'a':112, 't':0, 's':0}, {'r':153, 'g':255, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':153, 'g':204, 'b':255, 'a':112, 't':0, 's':0}, {'r':153, 'g':204, 'b':204, 'a':112, 't':0, 's':0}, {'r':153, 'g':204, 'b':153, 'a':112, 't':0, 's':0},
          {'r':153, 'g':204, 'b':102, 'a':112, 't':0, 's':0}, {'r':153, 'g':204, 'b': 51, 'a':112, 't':0, 's':0}, {'r':153, 'g':204, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':153, 'g':153, 'b':255, 'a':112, 't':0, 's':0}, {'r':153, 'g':153, 'b':204, 'a':112, 't':0, 's':0}, {'r':153, 'g':153, 'b':153, 'a':112, 't':0, 's':0},
          {'r':153, 'g':153, 'b':102, 'a':112, 't':0, 's':0}, {'r':153, 'g':153, 'b': 51, 'a':112, 't':0, 's':0}, {'r':153, 'g':153, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':153, 'g':102, 'b':255, 'a':112, 't':0, 's':0}, {'r':153, 'g':102, 'b':204, 'a':112, 't':0, 's':0}, {'r':153, 'g':102, 'b':153, 'a':112, 't':0, 's':0},
          {'r':153, 'g':102, 'b':102, 'a':112, 't':0, 's':0}, {'r':153, 'g':102, 'b': 51, 'a':112, 't':0, 's':0}, {'r':153, 'g':102, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':153, 'g': 51, 'b':255, 'a':112, 't':0, 's':0}, {'r':153, 'g': 51, 'b':204, 'a':112, 't':0, 's':0}, {'r':153, 'g': 51, 'b':153, 'a':112, 't':0, 's':0},
          {'r':153, 'g': 51, 'b':102, 'a':112, 't':0, 's':0}, {'r':153, 'g': 51, 'b': 51, 'a':112, 't':0, 's':0}, {'r':153, 'g': 51, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':153, 'g':  0, 'b':255, 'a':112, 't':0, 's':0}, {'r':153, 'g':  0, 'b':204, 'a':112, 't':0, 's':0}, {'r':153, 'g':  0, 'b':153, 'a':112, 't':0, 's':0},
          {'r':153, 'g':  0, 'b':102, 'a':112, 't':0, 's':0}, {'r':153, 'g':  0, 'b': 51, 'a':112, 't':0, 's':0}, {'r':153, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':102, 'g':255, 'b':255, 'a':112, 't':0, 's':0}, {'r':102, 'g':255, 'b':204, 'a':112, 't':0, 's':0}, {'r':102, 'g':255, 'b':153, 'a':112, 't':0, 's':0},
          {'r':102, 'g':255, 'b':102, 'a':112, 't':0, 's':0}, {'r':102, 'g':255, 'b': 51, 'a':112, 't':0, 's':0}, {'r':102, 'g':255, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':102, 'g':204, 'b':255, 'a':112, 't':0, 's':0}, {'r':102, 'g':204, 'b':204, 'a':112, 't':0, 's':0}, {'r':102, 'g':204, 'b':153, 'a':112, 't':0, 's':0},
          {'r':102, 'g':204, 'b':102, 'a':112, 't':0, 's':0}, {'r':102, 'g':204, 'b': 51, 'a':112, 't':0, 's':0}, {'r':102, 'g':204, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':102, 'g':153, 'b':255, 'a':112, 't':0, 's':0}, {'r':102, 'g':153, 'b':204, 'a':112, 't':0, 's':0}, {'r':102, 'g':153, 'b':153, 'a':112, 't':0, 's':0},
          {'r':102, 'g':153, 'b':102, 'a':112, 't':0, 's':0}, {'r':102, 'g':153, 'b': 51, 'a':112, 't':0, 's':0}, {'r':102, 'g':153, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':102, 'g':102, 'b':255, 'a':112, 't':0, 's':0}, {'r':102, 'g':102, 'b':204, 'a':112, 't':0, 's':0}, {'r':102, 'g':102, 'b':153, 'a':112, 't':0, 's':0},
          {'r':102, 'g':102, 'b':102, 'a':112, 't':0, 's':0}, {'r':102, 'g':102, 'b': 51, 'a':112, 't':0, 's':0}, {'r':102, 'g':102, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':102, 'g': 51, 'b':255, 'a':112, 't':0, 's':0}, {'r':102, 'g': 51, 'b':204, 'a':112, 't':0, 's':0}, {'r':102, 'g': 51, 'b':153, 'a':112, 't':0, 's':0},
          {'r':102, 'g': 51, 'b':102, 'a':112, 't':0, 's':0}, {'r':102, 'g': 51, 'b': 51, 'a':112, 't':0, 's':0}, {'r':102, 'g': 51, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':102, 'g':  0, 'b':255, 'a':112, 't':0, 's':0}, {'r':102, 'g':  0, 'b':204, 'a':112, 't':0, 's':0}, {'r':102, 'g':  0, 'b':153, 'a':112, 't':0, 's':0},
          {'r':102, 'g':  0, 'b':102, 'a':112, 't':0, 's':0}, {'r':102, 'g':  0, 'b': 51, 'a':112, 't':0, 's':0}, {'r':102, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':255, 'b':255, 'a':112, 't':0, 's':0}, {'r': 51, 'g':255, 'b':204, 'a':112, 't':0, 's':0}, {'r': 51, 'g':255, 'b':153, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':255, 'b':102, 'a':112, 't':0, 's':0}, {'r': 51, 'g':255, 'b': 51, 'a':112, 't':0, 's':0}, {'r': 51, 'g':255, 'b':  0, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':204, 'b':255, 'a':112, 't':0, 's':0}, {'r': 51, 'g':204, 'b':204, 'a':112, 't':0, 's':0}, {'r': 51, 'g':204, 'b':153, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':204, 'b':102, 'a':112, 't':0, 's':0}, {'r': 51, 'g':204, 'b': 51, 'a':112, 't':0, 's':0}, {'r': 51, 'g':204, 'b':  0, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':153, 'b':255, 'a':112, 't':0, 's':0}, {'r': 51, 'g':153, 'b':204, 'a':112, 't':0, 's':0}, {'r': 51, 'g':153, 'b':153, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':153, 'b':102, 'a':112, 't':0, 's':0}, {'r': 51, 'g':153, 'b': 51, 'a':112, 't':0, 's':0}, {'r': 51, 'g':153, 'b':  0, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':102, 'b':255, 'a':112, 't':0, 's':0}, {'r': 51, 'g':102, 'b':204, 'a':112, 't':0, 's':0}, {'r': 51, 'g':102, 'b':153, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':102, 'b':102, 'a':112, 't':0, 's':0}, {'r': 51, 'g':102, 'b': 51, 'a':112, 't':0, 's':0}, {'r': 51, 'g':102, 'b':  0, 'a':112, 't':0, 's':0},
          {'r': 51, 'g': 51, 'b':255, 'a':112, 't':0, 's':0}, {'r': 51, 'g': 51, 'b':204, 'a':112, 't':0, 's':0}, {'r': 51, 'g': 51, 'b':153, 'a':112, 't':0, 's':0},
          {'r': 51, 'g': 51, 'b':102, 'a':112, 't':0, 's':0}, {'r': 51, 'g': 51, 'b': 51, 'a':112, 't':0, 's':0}, {'r': 51, 'g': 51, 'b':  0, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':  0, 'b':255, 'a':112, 't':0, 's':0}, {'r': 51, 'g':  0, 'b':204, 'a':112, 't':0, 's':0}, {'r': 51, 'g':  0, 'b':153, 'a':112, 't':0, 's':0},
          {'r': 51, 'g':  0, 'b':102, 'a':112, 't':0, 's':0}, {'r': 51, 'g':  0, 'b': 51, 'a':112, 't':0, 's':0}, {'r': 51, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':255, 'b':255, 'a':112, 't':0, 's':0}, {'r':  0, 'g':255, 'b':204, 'a':112, 't':0, 's':0}, {'r':  0, 'g':255, 'b':153, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':255, 'b':102, 'a':112, 't':0, 's':0}, {'r':  0, 'g':255, 'b': 51, 'a':112, 't':0, 's':0}, {'r':  0, 'g':255, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':204, 'b':255, 'a':112, 't':0, 's':0}, {'r':  0, 'g':204, 'b':204, 'a':112, 't':0, 's':0}, {'r':  0, 'g':204, 'b':153, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':204, 'b':102, 'a':112, 't':0, 's':0}, {'r':  0, 'g':204, 'b': 51, 'a':112, 't':0, 's':0}, {'r':  0, 'g':204, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':153, 'b':255, 'a':112, 't':0, 's':0}, {'r':  0, 'g':153, 'b':204, 'a':112, 't':0, 's':0}, {'r':  0, 'g':153, 'b':153, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':153, 'b':102, 'a':112, 't':0, 's':0}, {'r':  0, 'g':153, 'b': 51, 'a':112, 't':0, 's':0}, {'r':  0, 'g':153, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':102, 'b':255, 'a':112, 't':0, 's':0}, {'r':  0, 'g':102, 'b':204, 'a':112, 't':0, 's':0}, {'r':  0, 'g':102, 'b':153, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':102, 'b':102, 'a':112, 't':0, 's':0}, {'r':  0, 'g':102, 'b': 51, 'a':112, 't':0, 's':0}, {'r':  0, 'g':102, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g': 51, 'b':255, 'a':112, 't':0, 's':0}, {'r':  0, 'g': 51, 'b':204, 'a':112, 't':0, 's':0}, {'r':  0, 'g': 51, 'b':153, 'a':112, 't':0, 's':0},
          {'r':  0, 'g': 51, 'b':102, 'a':112, 't':0, 's':0}, {'r':  0, 'g': 51, 'b': 51, 'a':112, 't':0, 's':0}, {'r':  0, 'g': 51, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':  0, 'b':255, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b':204, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b':153, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':  0, 'b':102, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b': 51, 'a':112, 't':0, 's':0}, {'r':238, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':221, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0}, {'r':187, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0}, {'r':170, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':136, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0}, {'r':119, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0}, {'r': 85, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r': 68, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0}, {'r': 34, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0}, {'r': 17, 'g':  0, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':238, 'b':  0, 'a':112, 't':0, 's':0}, {'r':  0, 'g':221, 'b':  0, 'a':112, 't':0, 's':0}, {'r':  0, 'g':187, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':170, 'b':  0, 'a':112, 't':0, 's':0}, {'r':  0, 'g':136, 'b':  0, 'a':112, 't':0, 's':0}, {'r':  0, 'g':119, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g': 85, 'b':  0, 'a':112, 't':0, 's':0}, {'r':  0, 'g': 68, 'b':  0, 'a':112, 't':0, 's':0}, {'r':  0, 'g': 34, 'b':  0, 'a':112, 't':0, 's':0},
          {'r':  0, 'g': 17, 'b':  0, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b':238, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b':221, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':  0, 'b':187, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b':170, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b':136, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':  0, 'b':119, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b': 85, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b': 68, 'a':112, 't':0, 's':0},
          {'r':  0, 'g':  0, 'b': 34, 'a':112, 't':0, 's':0}, {'r':  0, 'g':  0, 'b': 17, 'a':112, 't':0, 's':0}, {'r':238, 'g':238, 'b':238, 'a':112, 't':0, 's':0},
          {'r':221, 'g':221, 'b':221, 'a':112, 't':0, 's':0}, {'r':187, 'g':187, 'b':187, 'a':112, 't':0, 's':0}, {'r':170, 'g':170, 'b':170, 'a':112, 't':0, 's':0},
          {'r':136, 'g':136, 'b':136, 'a':112, 't':0, 's':0}, {'r':119, 'g':119, 'b':119, 'a':112, 't':0, 's':0}, {'r': 85, 'g': 85, 'b': 85, 'a':112, 't':0, 's':0},
          {'r': 68, 'g': 68, 'b': 68, 'a':112, 't':0, 's':0}, {'r': 34, 'g': 34, 'b': 34, 'a':112, 't':0, 's':0}, {'r': 17, 'g': 17, 'b': 17, 'a':112, 't':0, 's':0}
        ]
        console.log "default palette"
      else
        rawpalette = new Uint8Array ab.slice paletteBegin, paletteBegin + paletteLength
        for i in [0...paletteLength] by 4
          palette.push {r: rawpalette[i], g: rawpalette[i + 1], b: rawpalette[i + 2], a: 112, t: 0, s: 0}
        console.log "palette:"
        console.log palette
      # read voxel chunk
      @voxels = []
      [voxelCount] = new Uint32Array ab.slice voxelBegin, voxelBegin + 4
      console.log "voxel count: #{voxelCount}"
      console.warn "invalid length of voxel chunk" unless voxelBegin + 4 + 4 * voxelCount == voxelEnd
      rawvoxels = new Uint8Array ab.slice voxelBegin + 4, voxelBegin + 4 + 4 * voxelCount
      for i in [0...4 * voxelCount] by 4
        @voxels[rawvoxels[i]] = [] unless @voxels[rawvoxels[i]]?
        @voxels[rawvoxels[i]][rawvoxels[i + 2]] = [] unless @voxels[rawvoxels[i]][rawvoxels[i + 2]]? # order is z, x, y
        @voxels[rawvoxels[i]][rawvoxels[i + 2]][rawvoxels[i + 1]] = palette[rawvoxels[i + 3] - 1] # if you change it, change it in saving too
      console.log "voxels:"
      console.log @voxels
      callback()
    console.log "reading file with name: #{file.name}"
    fr.readAsArrayBuffer file

  export: ->
    data = [
      86, 79, 88, 32 # VOX_
      150, 0, 0, 0 # 150 (version)
      77, 65, 73, 78 # MAIN
      0, 0, 0, 0 # 0 (main chunk size)
    ]
    [x1, x2, x3, x4] = new Uint8Array new Uint32Array([@x]).buffer
    [y1, y2, y3, y4] = new Uint8Array new Uint32Array([@y]).buffer
    [z1, z2, z3, z4] = new Uint8Array new Uint32Array([@z]).buffer
    sizeChunk = [
      83, 73, 90, 69 # SIZE
      12, 0, 0, 0 # 12 (size chunk size)
      0, 0, 0, 0 # 0 (no children chunks)
      x1, x2, x3, x4 # width
      y1, y2, y3, y4 # height
      z1, z2, z3, z4 # depth
    ]
    voxelChunk = [] # add header with id and size info later
    paletteChunk = [
      82, 71, 66, 65 # RGBA
      0, 4, 0, 0 # 1024 (palette chunk size)
      0, 0, 0, 0 # 0 (no children chunks)
    ]
    helpPalette = {}
    for z in [0...@z] by 1
      for y in [0...@y] by 1
        for x in [0...@x] by 1 when @voxels[z]?[y]?[x]?
          rgba = ((@voxels[z][y][x].r << 24) | (@voxels[z][y][x].g << 16) | (@voxels[z][y][x].b << 8) | 255) >>> 0
          i = helpPalette[rgba]
          unless i?
            throw new Error "To many colors for Magica Voxel palette" unless paletteChunk.length < 1036
            paletteChunk = paletteChunk.concat [@voxels[z][y][x].r, @voxels[z][y][x].g, @voxels[z][y][x].b, 255]
            i = paletteChunk.length / 4 - 3
            helpPalette[rgba] = i
          voxelChunk = voxelChunk.concat [z, x, y, i] # change order if changed in loading
    paletteChunk = paletteChunk.concat [255, 255, 255, 255] while paletteChunk.length < 1036 # fill up palette with dummy data
    [s1, s2, s3, s4] = new Uint8Array new Uint32Array([1076 + voxelChunk.length]).buffer
    data = data.concat [s1, s2, s3, s4] # main chunk: child chunk aize
    data = data.concat sizeChunk
    [s1, s2, s3, s4] = new Uint8Array new Uint32Array([voxelChunk.length + 4]).buffer
    [c1, c2, c3, c4] = new Uint8Array new Uint32Array([voxelChunk.length / 4]).buffer
    data = data.concat [
      88, 89, 90, 73 # XYZI
      s1, s2, s3, s4 # size of voxel chunk
      0, 0, 0, 0 # 0 (no child chunks)
      c1, c2, c3, c4 # voxel count
    ]
    data = data.concat voxelChunk
    data = data.concat paletteChunk
    console.log "export Magica:"
    console.log data
    URL.createObjectURL new Blob [new Uint8Array data], type: 'application/octet-binary'

if typeof module == 'object' then module.exports = MagicaIO else window.MagicaIO = MagicaIO
