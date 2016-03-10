'use strict'
fs = require 'fs'

# ToDo: output console.log only in debug mode
util = require 'util'
console.log = (t) -> process.stdout.write(util.format.apply(util, arguments) + '\n') if t && t.indexOf && ~t.indexOf '%' # supress console.log output

global.atob = (a) -> new Buffer(a, 'base64').toString('binary')
global.btoa = (b) -> new Buffer(b, 'binary').toString('base64')

class global.FileReader
  readAsArrayBuffer: (path) ->
    fs.readFile path, (err, b) =>
      throw err if err?
      @result = new Uint8Array(b).buffer
      @onloadend()
  readAsText: (path) ->
    fs.readFile path, (err, @result) =>
      throw err if err?
      @onloadend()

module.exports =
  readFileAsUint8Array: (path, cb) ->
    fs.readFile path, (err, b) ->
      throw err if err?
      cb(b)
  readFileAsJSON: (path, cb) ->
    fs.readFile path, (err, data) ->
      throw err if err?
      cb(JSON.parse(data))
