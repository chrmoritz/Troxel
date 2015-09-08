fs = require 'fs'
exec = require('child_process').exec
stringify = require 'json-stable-stringify'
global.IO = require '../coffee/IO.coffee'
QubicleIO = require '../coffee/Qubicle.io.coffee'
{Base64IO} = require '../coffee/Troxel.io.coffee'
require '../test/TestUtils.coffee'
cpus = require('os').cpus().length

generateChangelog = (oldObj, newObj, path) ->
  log = ''
  for newName, newData of newObj
    if oldObj[newName]?
      if newData != oldObj[newName]
        log += "* updated blueprint: [#{newName}](//chrmoritz.github.io/Troxel/#b=#{newName})
                from [old version](//chrmoritz.github.io/Troxel/#m=#{oldObj[newName]})\n"
      delete oldObj[newName]
    else
      log += "* added new blueprint: [#{newName}](//chrmoritz.github.io/Troxel/#b=#{newName})\n"
  for name, data of oldObj
    log += "* removed blueprint: [#{name}](//chrmoritz.github.io/Troxel/#m=#{data})\n"
  fs.writeFile path, log, (err) ->
    throw err if err?
    process.stdout.write "Trove blueprints changelog successfully written to #{path}\n"
  # ToDo. Added, updated, renamed (same data), removed
    fs.readdir logDir, (err, files) ->
      throw err if err?
      files.splice files.indexOf('index.json'), 1
      fs.writeFile "#{logDir}/index.json", JSON.stringify(files), (err) ->
        throw err if err?
        process.stdout.write "Trove blueprints changelog index successfully written to #{logDir}/index.json\n"

models = {}
failedBlueprints = []
jsonPath = "#{process.cwd()}/tools/Trove.json"
logDir = "#{process.cwd()}/tools/TroveChangelog"
logPath = "#{logDir}/#{new Date().toISOString().split('T')[0]}.md"

if process.platform == 'darwin'
  trovedir = '/Applications/Trion\ Games/Trove-Live.app/Contents/Resources/Trove.app/Contents/Resources/'
  delcmd = 'rm -rf qbexport bpexport; mkdir qbexport bpexport'
  devtool = '../MacOS/Trove -tool'
  slash = '/'
else
  trovedir = 'C:/Program Files/Trove/'
  delcmd = 'del /q qbexport\\* bpexport\\* %appdata%\\Trove\\DevTool.log'
  devtool = 'Trove.exe -tool'
  slash = '\\'

process.chdir(process.argv[2] || trovedir)
exec delcmd, {timeout: 60000}, (err, stdout, stderr) ->
  throw err if err?
  exec "#{devtool} extractarchive blueprints bpexport & #{devtool} extractarchive blueprints/equipment/ring bpexport", {timeout: 60000}, (err, stdout, stderr) ->
    throw err if err? and (err.killed or err.signal? or err.code != 1) # ignore devtool error code 1
    fs.readdir 'bpexport', (err, files) ->
      throw err if err?
      toProcess = files.length
      processedOne = ->
        if --toProcess == 0
          oldModels = require(jsonPath)
          fs.writeFile jsonPath, stringify(models, space: '  '), (err) -> throw err if err?
          count = Object.keys(models).length
          process.stdout.write "\nbase64 data of #{count} blueprints successfully written to #{jsonPath}\nskipped #{failedBlueprints.length} broken blueprints:\n\n"
          process.stdout.write " * #{bp}\n" for bp in failedBlueprints
          process.stdout.write "\ncleaning up (could take a minute)...\n"
          exec delcmd, {timeout: 180000}, (err, stdout, stderr) ->
            throw err if err?
            process.stdout.write "finished cleaning up qbexport and bpexport\n"
          generateChangelog oldModels, models, logPath
      processSny = ->
        f = files.pop()
        return unless f? # all files processed
        if f.length > 10 and f.indexOf('.blueprint') == f.length - 10
          exp = f.split(slash).pop()
          exp = exp.substring(0, exp.length - 10)
          exec "#{devtool} copyblueprint -generatemaps 1 bpexport/#{f} qbexport/#{exp}.qb", {timeout: 15000}, (err, stdout, stderr) ->
            if err? and (err.killed or err.signal? or err.code != 1) # ignore devtool error code 1
              failedBlueprints.push(f)
              processedOne()
              process.stderr.write "#{toProcess} bp left: skipped #{f} because of trove devtool not responding\n"
              return setImmediate processSny
            qbf = 'qbexport/' + exp
            io = new QubicleIO m: qbf + '.qb', a: qbf + '_a.qb', t: qbf + '_t.qb', s: qbf + '_s.qb', ->
              [x, y, z, ox, oy, oz] = io.computeBoundingBox()
              io.resize x, y, z, ox, oy, oz
              models[exp] = new Base64IO(io).export(true, 2)
              process.stdout.write "#{toProcess} bp left: #{f}\n"
              processedOne()
            setImmediate processSny
        else
          processedOne()
          process.stdout.write "#{toProcess} bp left: skipped #{f} because not a blueprint\n"
          setImmediate processSny
      processSny() for i in [0...cpus*2] by 1
