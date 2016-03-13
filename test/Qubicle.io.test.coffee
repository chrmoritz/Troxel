'use strict'
fs = require 'fs'
should = require 'should'

require './TestUtils'
QubicleIO = require '../coffee/Qubicle.io'

describe 'QubicleIO', ->
  model = chr_knight = chr_knight_compressed = null
  before (done) ->
    model = require './models/chr_knight.json'
    t = 0
    fs.readFile 'test/models/chr_knight.qb', (err, data) ->
      return done(err) if err?
      chr_knight = new Uint8Array(data)
      done() if t++
    fs.readFile 'test/models/chr_knight_compressed.qb', (err, data) ->
      return done(err) if err?
      chr_knight_compressed = new Uint8Array(data)
      done() if t++
  describe 'import', ->
    it 'should be able to successfully import a .qb file', ->
      io = new QubicleIO([chr_knight.buffer])
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to successfully import a .qb file (compressed)', ->
      io = new QubicleIO([chr_knight_compressed.buffer])
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to successfully import a .qb file (multiple maps)'
    it 'should be able to successfully import a .qb file (mutliple matrices)'
  describe 'export', ->
    io = view = view_c = null
    before ->
      io = new QubicleIO model
    it 'should be able to successfully export to a .qb file', ->
      b = io.export(false)[0].should.eql(chr_knight)
    it 'should be able to successfully export to a .qb file (compressed)', ->
      io.export(true)[0].should.eql(chr_knight_compressed)
    it 'should be able to successfully export to a .qb file (multiple maps)'
    it 'should be able to successfully export to a .qb file (multiple matrices)'
  describe 'methods', ->
    io = null
    beforeEach ->
      io = new QubicleIO {x: 1, y: 1, z: 1, voxels: []}
      io.warn = []
    describe 'addValues', ->
      it 'should handle color format correctly', ->
        io.addValues 0, 0, 0, 0, 32, 64, 128, 1
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 128, g: 64, b: 32, a: 255, t: 0, s: 0})
      it 'should handle zOrientation correctly'
    describe 'addColorValues', ->
      it 'should add color values correctly and set default values for other parameters', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 0})
    describe 'addAlphaValues', ->
      it 'should add alpha values correctly', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addAlphaValues 0, 0, 0, 176, 176, 176
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 176, t: 0, s: 0})
      it 'should add alpha values correctly (fallback invalid data)', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addAlphaValues 0, 0, 0, 145, 32, 213
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 112, t: 0, s: 0})
    describe 'addTypeValues', ->
      it 'should add type values correctly: solid', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addTypeValues 0, 0, 0, 255, 255, 255
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 0})
      it 'should add type values correctly: glass', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addTypeValues 0, 0, 0, 128, 128, 128
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 1, s: 0})
      it 'should add type values correctly: tiled glass', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addTypeValues 0, 0, 0, 64, 64, 64
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 2, s: 0})
      it 'should add type values correctly: glowing solid', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addTypeValues 0, 0, 0, 255, 0, 0
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 3, s: 0})
      it 'should add type values correctly: glowing glass', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addTypeValues 0, 0, 0, 255, 255, 0
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 4, s: 0})
      it 'should add type values correctly: attachment point', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addTypeValues 0, 0, 0, 255, 0, 255
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 7, s: 0})
      it 'should add type values correctly: fallback', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addTypeValues 0, 0, 0, 32, 48, 64
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 0})
    describe 'addSpecularValues', ->
      it 'should add specular values correctly: rough', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addSpecularValues 0, 0, 0, 128, 0, 0
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 0})
      it 'should add specular values correctly: metal', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addSpecularValues 0, 0, 0, 0, 128, 0
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 1})
      it 'should add specular values correctly: water', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addSpecularValues 0, 0, 0, 0, 0, 128
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 2})
      it 'should add specular values correctly: iridescent', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addSpecularValues 0, 0, 0, 128, 128, 0
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 3})
      it 'should add specular values correctly: waxy', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addSpecularValues 0, 0, 0, 128, 0, 128
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 4})
      it 'should add specular values correctly: attachment point', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addSpecularValues 0, 0, 0, 255, 0, 255
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 7})
      it 'should add specular values correctly: fallback', ->
        io.addColorValues 0, 0, 0, 32, 64, 128
        io.addSpecularValues 0, 0, 0, 32, 48, 64
        io.voxels.should.have.propertyByPath(0, 0, 0).with.properties({r: 32, g: 64, b: 128, a: 255, t: 0, s: 0})
