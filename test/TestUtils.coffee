'use strict'
fs = require 'fs'

# ToDo: output console.log only in debug mode
util = require 'util'
console.log = (t) -> process.stdout.write(util.format.apply(util, arguments) + '\n') if t && t.indexOf && ~t.indexOf '%' # supress console.log output

global.URL = createObjectURL: (b) -> b
global.Blob = (@ab, @options) -> return
global.atob = (a) -> new Buffer(a, 'base64').toString('binary')
global.btoa = (b) -> new Buffer(b, 'binary').toString('base64')

class global.FileReader
  readAsArrayBuffer: (path) ->
    fs.readFile path, (err, b) =>
      throw err if err?
      @result = new ArrayBuffer b.length
      view = new Uint8Array @result
      view[i] = b[i] for i in [0...b.length] by 1
      @onloadend()
  readAsText: (path) ->
    fs.readFile path, (err, @result) =>
      throw err if err?
      @onloadend()

module.exports =
  readFileAsUint8Array: (path, callback) ->
    fs.readFile path, (err, b) ->
      throw err if err?
      ab = new ArrayBuffer b.length
      view = new Uint8Array ab
      view[i] = b[i] for i in [0...b.length] by 1
      callback(view)
  readFileAsJSON: (path, callback) ->
    fs.readFile path, (err, data) ->
      throw err if err?
      callback(JSON.parse(data))
  readFileAsText: (path, callback) ->
    fs.readFile path, (err, data) ->
      throw err if err?
      callback(data)
