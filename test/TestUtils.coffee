'use strict'
# ToDo: output console.log only in debug mode
util = require 'util'
console.log = (t) -> process.stdout.write(util.format.apply(util, arguments) + '\n') if t && t.indexOf && ~t.indexOf '%' # supress console.log output

global.atob = (a) -> new Buffer(a, 'base64').toString('binary')
global.btoa = (b) -> new Buffer(b, 'binary').toString('base64')
