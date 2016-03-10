'use strict'
should = require 'should'
{readFileAsJSON} = require './TestUtils.coffee'
{Base64IO, JsonIO} = require '../lib/index'

model = require './models/chr_knight.json'
base64 = require './models/chr_knight.base64.json'

describe 'Base64IO', ->
  describe 'import', ->
    it 'should be able to load from base64', ->
      io = new Base64IO base64.chr_knight
      io.should.have.ownProperty('readonly', 'expected io.readonly to be defined').eql(0)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to load from base64 (readonly)', ->
      io = new Base64IO base64.chr_knight_ro
      io.should.have.ownProperty('readonly', 'expected io.readonly to be defined').eql(1)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'export', ->
    io = null
    before ->
      io = new Base64IO model
    it 'should be able to export to base64', ->
      io.export(false).should.equal(base64.chr_knight)
    it 'should be able to export to base64 (readonly)', ->
      io.export(true).should.equal(base64.chr_knight_ro)

describe 'JsonIO', ->
  json = null
  before (done) ->
    readFileAsJSON 'test/models/chr_knight.json', (s) ->
      json = s
      done()
  describe 'import', ->
    it 'should be able to load from JSON', ->
      io = new JsonIO(JSON.stringify(json))
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
      io.export(false).should.eql(JSON.stringify(json))
    it 'should be able to export to JSON (pretty)', ->
      io.export(true).should.eql(JSON.stringify(json, null, '    '))
