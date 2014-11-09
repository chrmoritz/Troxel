should = require 'should'
global.IO = require '../coffee/IO.coffee'
TroveIO = require '../coffee/Trove.io.coffee'

describe 'TroveIO', ->
  describe 'import', ->
    it 'should be able to successfully import a .blueprint file'
  describe 'export', ->
    it 'should be able to successfully export to a .blueprint file'
