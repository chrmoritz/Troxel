fs = require 'fs'
exec = require('child_process').exec
stringify = require 'json-stable-stringify'
global.IO = require '../coffee/IO.coffee'
QubicleIO = require '../coffee/Qubicle.io.coffee'
{Base64IO} = require '../coffee/Troxel.io.coffee'
require '../test/TestUtils.coffee'
cpus = require('os').cpus().length

models = {}
failedBlueprints = []
jsonPath = process.cwd() + '/tools/Trove.json'
process.chdir(process.argv[2] || 'C:/Program Files/Trove/')
exec 'del /q qbexport\\* & del /q %appdata%\\Trove\\DevTool.log', {timeout: 60000}, (err, stdout, stderr) ->
  throw err if err?
  fs.readdir 'blueprints', (err, files) ->
    throw err if err?
    fs.readdir 'blueprints\\equipment\\ring', (err, ringRiles) ->
      ringRiles.forEach (e, i, a) -> a[i] = 'equipment\\ring\\' + e
      Array.prototype.push.apply files, ringRiles
      toProcess = files.length
      processedOne = ->
        if --toProcess == 0
          fs.writeFile jsonPath, stringify(models, space: '  '), (err) -> thow err if err?
          count = Object.keys(models).length
          process.stdout.write "base64 data of #{count} blueprints successfully written to static/Trove.json\nskipped #{failedBlueprints.length} broken blueprints:\n\n"
          process.stdout.write " * #{bp}\n" for bp in failedBlueprints
          process.stdout.write "\ndeleting qbexport (could take a minute)...\n"
          exec 'del /q qbexport\\*', {timeout: 180000}, (err, stdout, stderr) -> throw err if err?
      processSny = ->
        f = files.pop()
        return unless f? # all files processed
        if f.length > 10 and f.indexOf('.blueprint') == f.length - 10
          exp = f.split('\\').pop()
          exp = exp.substring(0, exp.length - 10)
          exec "Trove.exe -tool copyblueprint -generatemaps 1 blueprints\\#{f} qbexport\\#{exp}.qb", {timeout: 15000}, (err, stdout, stderr) ->
            if err? and (err.killed or err.signal? or err.code != 1) # ignore devtool error code 1
              failedBlueprints.push(f)
              processedOne()
              process.stderr.write "#{toProcess} bp left: skipped #{f} because of trove devtool not responding\n"
              return setImmediate processSny
            qbf = 'qbexport/' + exp
            io = new QubicleIO m: qbf + '.qb', a: qbf + '_a.qb', t: qbf + '_t.qb', s: qbf + '_s.qb', ->
              io.resize.apply io, io.computeBoundingBox()
              models[exp] = new Base64IO(io).export(true, 2)
              process.stdout.write "#{toProcess} bp left: #{f}\n"
              processedOne()
            setImmediate processSny
        else
          processedOne()
          process.stdout.write "#{toProcess} bp left: skipped #{f} because not a blueprint\n"
          setImmediate processSny
      processSny() for i in [0...cpus*2] by 1
