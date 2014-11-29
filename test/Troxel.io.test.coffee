should = require 'should'
global.IO = require '../coffee/IO.coffee'
{Base64IO, JsonIO} = require '../coffee/Troxel.io.coffee'
{readFileAsText} = require './TestUtils.coffee'

chr_knight_base64 =          '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'
chr_knight_base64_readonly = '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'
model = require './models/chr_knight.json'

describe 'Base64IO', ->
  describe 'import', ->
    it 'should be able to load from base64', ->
      io = new Base64IO chr_knight_base64
      io.should.have.ownProperty('readonly', 'expected io.readonly to be defined').eql(0)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(21, 'expected io.y to be 21')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(20, 'expected io.z to be 20')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to load from base64 (readonly)', ->
      io = new Base64IO chr_knight_base64_readonly
      io.should.have.ownProperty('readonly', 'expected io.readonly to be defined').eql(1)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(21, 'expected io.y to be 21')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(20, 'expected io.z to be 20')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'export', ->
    io = null
    before ->
      io = new Base64IO model
    it 'should be able to export to base64', ->
      io.export(false).should.equal(chr_knight_base64)
    it 'should be able to export to base64 (readonly)', ->
      io.export(true).should.equal(chr_knight_base64_readonly)

describe 'JsonIO', ->
  sjson = null
  before (done) ->
    readFileAsText 'test/models/chr_knight.json', (s) ->
      sjson = s
      done()
  describe 'import', ->
    it 'should be able to load from JSON', ->
      io = new JsonIO(sjson)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(21, 'expected io.y to be 21')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(20, 'expected io.z to be 20')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'export', ->
    io = null
    before ->
      io = new JsonIO model
    it 'should be able to export to JSON', ->
      io.export(false).should.eql(JSON.stringify(JSON.parse(sjson)))
    it 'should be able to export to JSON (pretty)', ->
      io.export(true).should.eql(JSON.stringify(JSON.parse(sjson), null, '    '))
