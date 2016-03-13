'use strict'
fs = require 'fs'
should = require 'should'

require './TestUtils'
MagicaIO = require '../coffee/Magica.io'

describe 'MagicaIO', ->
  model = chr_knight = chr_knight2 = null
  before (done) ->
    model = require './models/chr_knight.json'
    fs.readFile 'test/models/chr_knight.vox', (err, data) ->
      return done(err) if err?
      chr_knight = new Uint8Array(data)
      done()
  describe 'import', ->
    it 'should be able to successfully import a .vox file', ->
      io = new MagicaIO(chr_knight.buffer)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'export', ->
    io = view = null
    before (done) ->
      io = new MagicaIO model
      fs.readFile 'test/models/chr_knight_export.vox', (err, data) ->
        return done(err) if err?
        view = data
        done()
    it 'should be able to successfully export to a .vox file', ->
      io.export().should.eql(view)
