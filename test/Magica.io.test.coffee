'use strict'
should = require 'should'
{readFileAsUint8Array} = require './TestUtils.coffee'
{MagicaIO} = require '../lib/index'

model = require './models/chr_knight.json'

describe 'MagicaIO', ->
  describe 'import', ->
    it 'should be able to successfully import a .vox file', (done) ->
      io = new MagicaIO 'test/models/chr_knight.vox', ->
        io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
        io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
        io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
        io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
        JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
        done()
  describe 'export', ->
    io = view = null
    before (done) ->
      io = new MagicaIO model
      readFileAsUint8Array 'test/models/chr_knight_export.vox', (v) ->
        view = v
        done()
    it 'should be able to successfully export to a .vox file', ->
      b = io.export()
      b.should.have.ownProperty('options', 'expected blob.options to be defined').with.ownProperty('type').equal('application/octet-binary')
      b.should.have.ownProperty('ab', 'expected blob.ab to be defined')
      (new Uint8Array b.ab[0]).should.eql(view)
