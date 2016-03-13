'use strict'
fs = require 'fs'
should = require 'should'

require './TestUtils'
JsonIO = require '../coffee/JSON.io'

describe 'JsonIO', ->
  model = null
  before ->
    model = require './models/chr_knight.json'
  describe 'import', ->
    it 'should be able to load from JSON', ->
      io = new JsonIO(JSON.stringify(model))
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'export', ->
    io = null
    before ->
      io = new JsonIO model
    it 'should be able to export to JSON', ->
      io.export(false).should.eql(JSON.stringify(model))
    it 'should be able to export to JSON (pretty)', ->
      io.export(true).should.eql(JSON.stringify(model, null, '    '))
