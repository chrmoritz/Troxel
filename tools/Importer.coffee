fs = require 'fs'
exec = require('child_process').exec
global.IO = require '../coffee/IO.coffee'
QubicleIO = require '../coffee/Qubicle.io.coffee'
{Base64IO} = require '../coffee/Troxel.io.coffee'
require '../test/TestUtils.coffee'

models = {}
jsonPath = process.cwd() + '/static/Trove.json'
process.chdir(process.argv[2] || 'C:/Program Files/Trove/')
fs.readdir 'blueprints', (err, files) ->
  throw err if err?
  toProcess = files.length
  failedBlueprints = []
  processedOne = ->
    process.stdout.write "#{toProcess} blueprints remaining: #{f}\n"
    if --toProcess == 0
      fs.writeFile jsonPath, JSON.stringify(models), -> thow err if err?
      process.stdout.write 'base64 data successfully written to static/Trove.json\nskipped broken blueprints:\n'
      process.stdout.write "#{bp}, " for bp in failedBlueprints
  processSny = -> # Trove doesn't like spawning 1k+ instances at the same time ;-)
    f = files.pop()
    return unless f? # all files processed
    if f.length > 10 and f.indexOf('.blueprint') == f.length - 10
      exec 'devtool_dungeon_blueprint_to_QB.bat blueprints/' + f, {timeout: 5000},(err, stdout, stderr) ->
        if err?
          failedBlueprints.push(f)
          processedOne()
          return process.nextTick processSny
        qbf = 'qbexport/' + f.substring 0, f.length - 10
        try
          io = new QubicleIO m: qbf + '.qb', a: qbf + '_a.qb', t: qbf + '_t.qb', s: qbf + '_s.qb', ->
            models[f.substring(0, f.length - 10)] = new Base64IO(io).export(true)
            processedOne()
        catch
          failedBlueprints.push(f)
          processedOne()
        process.nextTick processSny
    else
      processedOne()
      process.nextTick processSny
  processSny() for i in [0...4] # 4 parallel jobs
