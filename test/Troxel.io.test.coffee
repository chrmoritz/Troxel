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
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to load from base64 (readonly)', ->
      io = new Base64IO chr_knight_base64_readonly
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
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
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
