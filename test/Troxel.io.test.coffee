should = require 'should'
global.IO = require '../coffee/IO.coffee'
{Base64IO, JsonIO} = require '../coffee/Troxel.io.coffee'
{readFileAsText} = require './TestUtils.coffee'

chr_knight_base64 =          'FBUUAP9AlUAAqKiocJJAAKioqHCSQADc3NxwkkAA3NzccP9A/0DSQACoqKhwkkAAREREcJJAAERERHCSQABERERwkkAAREREcJJAANzc3HD/QP9AqkAAqKiocKZAAHR0dHCSQAB0dHRwkkAAqKiocJJAAKioqHCmQADc3Nxw/0D/QNJAAERERHCSQABERERw/0DuQACYZDBwkkAAmGQwcJJAAJhkMHCSQACYZDBwkkAAmGQwcJJAAJhkMHCSQACYZDBwkkAAmGQwcJJAAMyYZHCSQABERERwkkAAzJhkcP9A/0CWQAD8zJhw/0DGQAB0dHRwkkAAiIiIcP9A2kAAMJhkcM1AggB0dHRwj0AAdHR0cEAAdHR0cEAAdHR0cI5AgQB0dHRwQIEAdHR0cI5AAHR0dHBAAHR0dHBAAHR0dHCPQIIAdHR0cJFAAHR0dHD/QNhAAACYMHAAMMwwcAAAmDBwADDMMHAAAJgwcKNAAPyYAHAA/MyYcJFAAPyYAHAAAJgwcAD8mABwj0AA/JgAcECCAPyYAHCOQAD8mABwAPzMMHCBAPyYAHAAiIiIcI5AAPyYAHAAzJgwcIIA/JgAcAB0dHRwjEAAqKiocIEA/JgAcACIiIhwgQD8mABwAHR0dHCMQACoqKhwAPyYAHAAiIiIcAD8mABwAHR0dHAA/JgAcAB0dHRwjUCEAHR0dHD/QLBAAJhkMHCSQACYZDBwkkAA/MyYcJBAgQAwzDBwAPyYAHCBADDMMHCPQAAwzDBwAACYMHAAMMwwcJBAADDMMHAA/JgAcAAwzDBwj0CEAPyYAHCPQAD8mGRwgwD8mABwjkAAEBAQcIIA/JgAcIEAdHR0cI1AhAD8mABwAHR0dHCLQACoqKhwAIiIiHCEAPyYAHAAdHR0cItAAKioqHCEAPyYAHAAdHR0cI1AAIiIiHCCAPyYAHAAdHR0cI9AggB0dHRw/0DXQIQAAJgwcI9AAACYMHAA/JgAcAAAmDBwkEAAAJgwcAD8mABwAACYMHCQQAAwzABwgwD8mABwjkAA/JhkcIIA/JgAcI9AAPzMmHCBAPyYAHAAdHR0cI5AhAD8mABwgQB0dHRwi0AAqKiocIUA/JgAcAB0dHRwi0AAqKiocIQA/JgAcAB0dHRwjUAAiIiIcIIA/JgAcAB0dHRwj0CCAIiIiHD/QNdAhAAwzDBwj0AAMMwwcAD8mABwADDMMHCQQAAwzDBwAPyYAHAAMMwwcJBAADDMMHCDAPyYAHCOQAD8zJhwggD8mABwj0AA/MyYcIEA/JgAcAB0dHRwj0CDAPyYAHCBAHR0dHCLQAC4uLhwAIiIiHCEAPyYAHAAdHR0cItAALi4uHCEAPyYAHAAdHR0cI1AAIiIiHCCAPyYAHAAdHR0cI9AggCIiIhw/0CdQACYZDBwkkAAmGQwcJJAAPzMmHCQQIEAAJgwcAD8mABwgQAAmDBwj0AAAJgwcAAwzDBwAACYMHCQQAAwzDBwgQAwmGRwAGSYMHAA/JgAcI1AgwD8mABwAPyYMHCPQAD8zJhwgwD8mABwjkAAEBAQcIIA/JgAcIEAdHR0cI1AhAD8mABwAHR0dHCLQAC4uLhwAIiIiHCEAPyYAHAAdHR0cItAALi4uHCEAPyYAHAAdHR0cI1AAIiIiHCCAPyYAHAAdHR0cI9AggCIiIhw/0DXQAAwzDBwAACYMHAAMMwwcAAAmDBwADDMMHCTQAD8mABwjkAA/JgAcJJAAPyYAHAAAJgwcIIA/JgAcI1AAPyYAHBAAPyYMHCBAPyYAHCOQIMA/JgAcACIiIhwjkAA/JgAcADMmDBwggD8mABwAHR0dHCMQAC4uLhwgQD8mABwAIiIiHCBAPyYAHAAdHR0cIxAAOzs7HAA/JgAcACIiIhwAPyYAHAAiIiIcAD8mABwAHR0dHCNQIIAiIiIcIEAdHR0cP9A7EAA/MyYcIFAAPyYAHCjQAD8zJhwgUAA/JgAcKRAAPyYAHCQQIIAiIiIcI9AAIiIiHBAAIiIiHBAAIiIiHCOQIEAiIiIcECBAIiIiHCOQACIiIhwQACIiIhwQACIiIhwj0CCAIiIiHCRQACIiIhw/0DuQAD8zJhwgUAA/JgAcKVAAPyYAHD/QIhAAIiIiHCSQACoqKhw/0DJQAD8mABw/0D/QP9AtUAA/JgAcKRAAPyYAHD/QP9A/0CPQAD8mABw/0D/QP9A/0D/QP9A/0D/QPtA'
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
