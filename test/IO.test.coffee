'use strict'
should = require 'should'
require './TestUtils'
Base64IO = require '../coffee/Troxel.io'
IO = require '../coffee/IO'

model = require './models/chr_knight.json'
base64 = require './models/chr_knight.base64.json'

describe 'IO', ->
  describe 'constructor', ->
    it 'should accept an object', ->
      io = new IO x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}]]]
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(1, 'expected io.x to be 1')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(1, 'expected io.y to be 1')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(1, 'expected io.z to be 1')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined').with.propertyByPath(0, 0, 0).with.properties({r: 128, g: 64, b: 32, a: 255, t: 1, s: 2})
    it 'should accept another instance of IO', ->
      io2 = new IO x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}]]]
      io = new IO io2
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(1, 'expected io.x to be 1')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(1, 'expected io.y to be 1')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(1, 'expected io.z to be 1')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined').with.propertyByPath(0, 0, 0).with.properties({r: 128, g: 64, b: 32, a: 255, t: 1, s: 2})
    it 'should accept a Base64IO (inherit from IO)', ->
      io2 = new Base64IO base64.chr_knight
      io = new IO io2
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'verify', ->
    it 'should verify the integrity of an IO instance', ->
      new IO({x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}]]]}).verify().should.be.true
      new IO({x: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}]]]}).verify().should.be.false
      new IO({x: 0, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}]]]}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: 42}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}]], []]}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}], []]]}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 1, s: 2}, {}]]]}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: [[[42]]]}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: [[[{r: 128, b: 32, a: 255, t: 1, s: 2}]]]}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 9000, b: 32, a: 255, t: 1, s: 2}]]]}).verify().should.be.false
      new IO({x: 1, y: 1, z: 1, voxels: [[[{r: 128, g: 64, b: 32, a: 255, t: 8, s: 2}]]]}).verify().should.be.false
  describe 'rotate', ->
    it 'should be able to rotate +x', ->
      io = new Base64IO base64.chr_knight_rnx
      io.rotateX(true)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to rotate -x', ->
      io = new Base64IO base64.chr_knight_rpx
      io.rotateX(false)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to rotate +y', ->
      io = new Base64IO base64.chr_knight_rny
      io.rotateY(true)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to rotate -y', ->
      io = new Base64IO base64.chr_knight_rpy
      io.rotateY(false)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to rotate +z', ->
      io = new Base64IO base64.chr_knight_rnz
      io.rotateZ(true)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to rotate -z', ->
      io = new Base64IO base64.chr_knight_rpz
      io.rotateZ(false)
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'move', ->
    it 'should be able to move +x'
    it 'should be able to move -x'
    it 'should be able to move +y'
    it 'should be able to move -y'
    it 'should be able to move +z'
    it 'should be able to move -z'
  describe 'mirror', ->
    it 'should be able to mirror x', ->
      io = new Base64IO base64.chr_knight_mx
      io.mirrorX()
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to mirror y', ->
      io = new Base64IO base64.chr_knight_my
      io.mirrorY()
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
    it 'should be able to mirror z', ->
      io = new Base64IO base64.chr_knight_mz
      io.mirrorZ()
      io.should.have.ownProperty('x', 'expected io.x to be defined').equal(20, 'expected io.x to be 20')
      io.should.have.ownProperty('y', 'expected io.y to be defined').equal(20, 'expected io.y to be 20')
      io.should.have.ownProperty('z', 'expected io.z to be defined').equal(21, 'expected io.z to be 21')
      io.should.have.ownProperty('voxels', 'expected io.voxels to be defined')
      JSON.parse(JSON.stringify(io.voxels)).should.eql(model.voxels)
  describe 'resize', ->
    it 'should be able to resize the voxel model'
