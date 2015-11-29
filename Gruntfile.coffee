'use strict'
module.exports = (grunt) ->
  fs = require 'fs'
  execFile = require('child_process').execFile
  stringify = require 'json-stable-stringify'
  require('time-grunt')(grunt)

  grunt.initConfig {
    pkg: grunt.file.readJSON('package.json'),
    coffeelint: {
      options: {
        configFile: 'coffeelint.json'
      },
      unix: ['coffee/*.coffee', 'test/*.coffee', 'tools/*.coffee', 'Gruntfile.coffee'],
      win: {
        files: {
          src: ['coffee/*.coffee', 'test/*.coffee', 'tools/*.coffee', 'Gruntfile.coffee']
        },
        options: {
          'line_endings': {
            'level': 'ignore'
          }
        }
      }
    },
    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          require: 'coffee-script/register',
          timeout: 5000
        },
        src: 'test/*.coffee'
      }
    },
    clean: {
      js: 'js',
      dist: 'dist/*'
    },
    bower: {
      install: {
        options: {
          targetDir: 'dist/static',
          layout: (type, component, source) -> type
          verbose: true
        }
      }
    },
    coffee: {
      glob_to_multiple: {
        expand: true,
        cwd: 'coffee',
        src: '*.coffee',
        dest: 'js/',
        ext: '.js',
        extDot: 'last'
      }
    },
    uglify: {
      options: {
        screwIE8: true
      },
      main: {
        files: {'dist/static/troxel.min.js': ['js/IO.js', 'js/Qubicle.io.js', 'js/Magica.io.js', 'js/Zoxel.io.js', 'js/Troxel.io.js',
                                              'js/Renderer.js', 'js/Editor.js', 'js/Controls.js', 'js/TroveCreationsLint.js', 'js/Main.js']}
      },
      postEffects: {
        files: {'dist/static/js/threePost.min.js': ['bower_components/threejs-examples/examples/js/shaders/SSAOShader.js',
                                                    'bower_components/threejs-examples/examples/js/shaders/FXAAShader.js',
                                                    'bower_components/threejs-examples/examples/js/shaders/CopyShader.js',
                                                    'bower_components/threejs-examples/examples/js/postprocessing/EffectComposer.js',
                                                    'bower_components/threejs-examples/examples/js/postprocessing/ShaderPass.js'
                                                    'bower_components/threejs-examples/examples/js/postprocessing/RenderPass.js'
                                                    'bower_components/threejs-examples/examples/js/postprocessing/MaskPass.js']}
      },
      lib: {
        options: {
          banner: '/*!\n * libTroxel (https://github.com/chrmoritz/Troxel)\n * Copyright 2014 Christian Moritz\n * ' +
                  'Licensed under GNU LGPL v3.0 (https://github.com/chrmoritz/Troxel/blob/master/LICENSE.txt)\n */\n'
        },
        files: {'dist/static/libTroxel.min.js': ['js/IO.js', 'js/Troxel.io.js', 'js/Renderer.js', 'js/libTroxel.js',
                                                 'bower_components/threejs/build/three.min.js', 'js/Controls.js']}
      }
    },
    jade: {
      index:{
        files: 'dist/index.html': 'views/index.jade'
      },
      changelog:{
        files: 'dist/static/Recent_Changes.html': 'views/Recent_Changes.jade'
      }
    },
    concat: {
      options: {
        banner: 'callback(',
        footer: ');',
        process: (c, s) -> c.replace(/\s/g, '')
      },
      jsonp: {
        src: 'tools/Trove.json',
        dest: 'dist/static/Trove.json.js'
      }
    },
    copy: {
      json: {src: 'tools/Trove.json', dest: 'dist/static/Trove.json', options: process: (c, s) -> c.replace(/\s/g, '')}
      appcache: {src: 'tools/troxel.appcache', dest: 'dist/troxel.appcache'},
      typeahead: {src: 'bower_components/typehead.js/dist/typeahead.bundle.min.js', dest: 'dist/static/js/typeahead.min.js'},
      example: {src: 'test/libTroxelTest.html', dest: 'dist/static/libTroxelTest.html'}
    },
    pages: {
      serve: {
        options: {
          src: 'dist',
          dest: '.jekyll',
          baseurl: '/Troxel',
          serve: true,
          watch: true
        }
      }
    },
    watch: {
      options: {
        interrupt: true,
      },
      coffee: {
        files: 'coffee/*',
        tasks: ['coffee', 'uglify:main', 'uglify:lib']
      },
      jade: {
        files: 'views/*',
        tasks: 'jade'
      },
      appcache: {
        files: 'tools/troxel.appcache',
        tasks: 'copy:appcache'
      }
    },
    concurrent: {
      options: {
        logConcurrentOutput: true
      },
      serve: ['watch', 'pages']
    },
    notify_hooks: options: success: true
  }

  npmTasks = ['grunt-continue', 'grunt-mocha-test', 'grunt-coffeelint', 'grunt-contrib-clean', 'grunt-bower-task', 'grunt-contrib-coffee', 'grunt-contrib-uglify',
              'grunt-contrib-jade', 'grunt-contrib-concat', 'grunt-contrib-copy', 'grunt-jekyll-pages', 'grunt-contrib-watch', 'grunt-concurrent']
  grunt.loadNpmTasks t for t in npmTasks
  unless process.env.CI
    grunt.loadNpmTasks 'grunt-notify'
    grunt.task.run 'notify_hooks'

  grunt.registerTask 'default', ['test', 'build']
  grunt.registerTask 'test', ['continue:on', 'lint', 'continue:off', 'mochaTest', 'continue:fail-on-warning']
  grunt.registerTask 'build', ['clean', 'bower', 'coffee', 'uglify', 'jade', 'concat', 'copy']
  grunt.registerTask 'lint', 'runs the platform specific coffeelint task', -> grunt.task.run if process.platform == 'win32' then 'coffeelint:win' else 'coffeelint:unix'
  grunt.registerTask 'mocha', 'mochaTest'
  grunt.registerTask 'serve', ['build', 'concurrent:serve']

  grunt.registerTask 'import', 'imports Trove blueprints', (jobs) ->
    done = @async()
    global.IO = require './coffee/IO.coffee'
    QubicleIO = require './coffee/Qubicle.io.coffee'
    {Base64IO} = require './coffee/Troxel.io.coffee'
    require './test/TestUtils.coffee'
    if process.platform == 'darwin'
      trovedir = '/Applications/Trion Games/Trove-Live.app/Contents/Resources/Trove.app/Contents/Resources'
      devtool = '../MacOS/Trove'
    else
      trovedir = 'C:\\Program Files (x86)\\Glyph\\Games\\Trove\\Live'
      devtool = 'Trove.exe'
    repo = process.cwd()
    jsonPath = "#{repo}/tools/Trove.json"
    models = {}
    oldModels = require(jsonPath)

    readline = require 'readline'
    join = require('path').join
    testAndChdirTrovedir = (cb) ->
      fs.access join(trovedir, devtool), fs.R_OK, (err) ->
        if err?
          rl = readline.createInterface input: process.stdin, output: process.stdout
          grunt.log.errorlns "\nWarning: Can't find the Trove executable. Please enter the path to Trove's 'Live' directory " +
                             "(defaults to C:\\Program Files (x86)\\Glyph\\Games\\Trove\\Live) or leave it empty to abort!"
          rl.question ">> Path to Trove's Live directory: ", (path) ->
            return rl.emit 'SIGINT' if path == ''
            trovedir = path
            rl.close()
            testAndChdirTrovedir cb
          rl.on 'SIGINT', ->
            rl.close()
            grunt.fail.warn "Skipped importing Trove blueprints because of no Trove directory specified."
        else
          cb()

    rimraf = require 'rimraf'
    cleanup = (setup, cb) ->
      i = if setup then 4 else 2
      rimrafCb = (err) ->
        throw err if err?
        cb() if --i == 0
      rimraf 'bpexport/*', rimrafCb
      rimraf 'qbexport/*', rimrafCb
      if setup
        if process.platform == 'darwin' # OS X: fix Trove executable permissions + delete DevTool.log
          i++
          fs.chmod '../MacOS/Trove', 0o744, rimrafCb
          rimraf join(process.env.HOME, 'Documents/Trion Worlds/Trove/DevTool.log'), rimrafCb
        else # Windows: delete DevTool.log
          rimraf '%appdata%\\Trove\\DevTool.log', rimrafCb
        fs.stat 'qbexport', (err, stats) -> # create qbexport directory
          if err? || !stats.isDirectory()
            fs.mkdir 'qbexport', 0o755, rimrafCb
          else
            rimrafCb()

    async = require 'async'
    extractBlueprintArchives = (cb) ->
      async.each ['blueprints/equipment/ring', 'blueprints'], ((archive, cb2) ->
        execFile devtool, ['-tool', 'extractarchive', archive, 'bpexport'], {timeout: 60000}, (err, stdout, stderr) ->
          return cb2(err) if err? and (err.killed or err.signal? or err.code != 1) # ignore devtool error code 1
          cb2()
      ), (err) -> cb(err)

    crypto = require 'crypto'
    getChangedBlueprints = (cb) ->
      fs.readdir 'bpexport', (err, files) ->
        return cb(err) if err?
        grunt.log.writeln "comparing sha256 hashes of #{files.length} blueprints to determine changed ones..."
        oldSha256 = require "#{repo}/tools/Trove_sha256.json"
        newSha256 = {}
        changedFiles = []
        async.each files, ((f, cb2) ->
          shasum = crypto.createHash 'sha256'
          s = fs.ReadStream "bpexport/#{f}"
          s.on 'data', (d) ->
            shasum.update d
          s.on 'error', (err) ->
            cb2(err)
          s.on 'end', ->
            newSha256[f] = shasum.digest 'hex'
            exp = f.substring(0, f.length - 10)
            if oldSha256[f]? and oldSha256[f] == newSha256[f] and oldModels[exp]?
              models[exp] = oldModels[exp]
            else
              changedFiles.push(f)
            cb2()
        ), (err2) ->
          return cb(err2) if err2?
          fs.writeFile "#{repo}/tools/Trove_sha256.json", stringify(newSha256, space: '  '), (err3) ->
            throw err3 if err3?
          cb(null, changedFiles)

    isTTY = process.stdout.isTTY
    if isTTY
      cursor = require('ansi')(process.stdout)
      barWidth = process.stdout.getWindowSize()[0] - 16

    testAndChdirTrovedir ->
      process.chdir trovedir
      grunt.log.writeln 'cleaning and setting up import environment (could take a minute)...'
      cleanup true, ->
        grunt.log.writeln 'extracting blueprint archives (could take a minute)...'
        extractBlueprintArchives (err) ->
          throw err if err?
          getChangedBlueprints (err, files) ->
            throw err if err?
            grunt.log.writeln "Found #{files.length} new or updated blueprints for reimport\n\n"
            toProcess = totalBps = files.length
            failedBlueprints = []
            retry = true
            queue = async.queue(((f, cb) ->
              if f.length > 10 and f.indexOf('.blueprint') == f.length - 10
                exp = f.substring(0, f.length - 10)
                execFile devtool, ['-tool', 'copyblueprint', '-generatemaps', '1', "bpexport/#{f}", "qbexport/#{exp}.qb"], {timeout: 15000}, (err, stdout, stderr) ->
                  if err? and (err.killed or err.signal? or err.code != 1) # ignore devtool error code 1
                    failedBlueprints.push(f)
                    processedOne "skipped (devtool not responding): #{f}", true, false
                    return cb()
                  qbf = 'qbexport/' + exp
                  io = new QubicleIO m: qbf + '.qb', a: qbf + '_a.qb', t: qbf + '_t.qb', s: qbf + '_s.qb', ->
                    [x, y, z, ox, oy, oz] = io.computeBoundingBox()
                    io.resize x, y, z, ox, oy, oz
                    models[exp] = new Base64IO(io).export(true, 2)
                    processedOne "imported: #{f}", false, io.warn.length > 0
                    queue.drain() if toProcess == 0
                  cb() # opening qb files can run concurrent to devtool tasks
              else
                processedOne "skipped (not a blueprint): #{f}", true, false
                setImmediate cb
            ), parseInt(jobs) || 2 * require('os').cpus().length)
            processedOne = (msg, err, warn) ->
              toProcess--
              cursor.up(1).horizontalAbsolute(0).eraseLine() if isTTY and not warn
              grunt.log[if err then 'errorlns' else 'writelns'] msg
              if isTTY
                s = Math.round toProcess/totalBps * barWidth
                cursor.write "╢#{Array(barWidth - s).join('█')}#{Array(s).join('░')}╟ #{toProcess} bp left\n"
            queue.drain = ->
              return unless toProcess == 0
              if failedBlueprints.length > 0 and retry # retry failedBlueprints in series
                retry = false
                grunt.log.errorlns "\nretrying #{failedBlueprints.length} broken blueprints in series\n\n"
                toProcess = totalBps = failedBlueprints.length
                failedBlueprints = []
                queue.concurrency = 1
                return queue.push failedBlueprints
              grunt.config.set 'changelog.oldModels', require(jsonPath)
              grunt.config.set 'changelog.newModels', models
              fs.writeFile jsonPath, stringify(models, space: '  '), (err) ->
                throw err if err?
                count = Object.keys(models).length
                grunt.log.writeln ''
                grunt.log.ok "base64 data of #{count} (#{totalBps} new) blueprints successfully written to #{jsonPath}"
                grunt.log.errorlns "skipped #{failedBlueprints.length} broken blueprints:" if failedBlueprints.length > 0
                grunt.log.writeln " * #{bp}" for bp in failedBlueprints
                grunt.log.writeln "cleaning up (could take a minute)..."
              cleanup false, ->
                grunt.log.ok "finished cleaning up bpexport and qbexport"
                process.chdir repo
                done()
            queue.push files

  grunt.registerTask 'loadGitChangelogData', 'usage: loadGitChangelogData:oldsha[:newsha] (newsha defaults to HEAD)', (oldsha, newsha) ->
    done = @async()
    t = false
    grunt.fail.warn 'now gitsha passed: usage: loadGitChangelogData:oldsha[:newsha] (newsha defaults to HEAD)' unless oldsha?
    execFile 'git', ['show', "#{oldsha}:tools/Trove.json"], {timeout: 10000, maxBuffer: 104857600}, (err, stdout, stderr) ->
      throw err if err?
      grunt.config.set 'changelog.oldModels', JSON.parse stdout.toString()
      done() if t
      t = true
    unless newsha?
      grunt.config.set 'changelog.newModels', require('./tools/Trove.json')
      t = true
    else
      execFile 'git', ['show', "#{newsha}:tools/Trove.json"], {timeout: 10000, maxBuffer: 104857600}, (err, stdout, stderr) ->
        throw err if err?
        grunt.config.set 'changelog.newModels', JSON.parse stdout.toString()
        done() if t
        t = true

  grunt.registerTask 'generateTroveChangelogJSON', 'usage: generateTroveChangelogJSON[:dateString]
                      (requires either import or loadGitChangelogData to be run beforehand)', (date) ->
    done = @async()
    grunt.config.requires 'changelog.oldModels', 'changelog.newModels'
    newObj = grunt.config.get 'changelog.newModels'
    oldObj = grunt.config.get 'changelog.oldModels'
    logDir = "#{process.cwd()}/tools/TroveChangelog"
    logPath = "#{logDir}/#{date || new Date().toISOString().split('T')[0]}.json"
    log = added: [], changed: [], renamed: [], removed: [], removedOrRenamed: (oldName, oldData) ->
      for addName, i in @added
        if oldData == newObj[addName]
          o = {}
          o[oldName] = addName
          @renamed.push o
          return @added.splice i, 1
      o = {}
      o[oldName] = oldData
      @removed.push o
    for newName, newData of newObj
      if oldObj[newName]?
        if newData != oldObj[newName]
          o = {}
          o[newName] = oldObj[newName]
          log.changed.push o
        delete oldObj[newName]
      else
        log.added.push newName
    for oldName, oldData of oldObj
      log.removedOrRenamed oldName, oldData
    delete log[e] for e in ['added', 'changed', 'renamed', 'removed'] when log[e].length == 0
    fs.writeFile logPath, stringify(log), (err) ->
      throw err if err?
      grunt.log.oklns "Trove blueprints changelog successfully written to #{logPath}\n"
      fs.readdir logDir, (err, files) ->
        throw err if err?
        files.splice files.indexOf('index.jsoun'), 1
        fs.writeFile "#{logDir}/index.json", stringify(files), (err) ->
          throw err if err?
          grunt.log.oklns "Trove blueprints changelog index successfully written to #{logDir}/index.json\n"
          done()
