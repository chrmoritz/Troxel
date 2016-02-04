'use strict'
should = require 'should'
{readFileAsJSON} = require './TestUtils.coffee'
{ZoxelIO} = require '../tools/index'

model = require './models/chr_knight.json'

describe 'ZoxelIO', ->
  describe 'import', ->
    it 'should be able to successfully import a .zox file', (done) ->
      io = new ZoxelIO 'test/models/chr_knight.zox', ->
        io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
        io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
        io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
        io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
        JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
        done()
  describe 'export', ->
    data = null
    before (done) ->
      readFileAsJSON 'test/models/chr_knight.zox', (d) ->
        data = d
        done()
    it 'should be able to successfully export to a .zox file', ->
      json = (new ZoxelIO model).export()
      json.should.startWith('data:application/octet-binary;base64,')
      JSON.parse(atob(json.substr(37))).should.eql(data)
