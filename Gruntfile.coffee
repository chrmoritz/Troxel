module.exports = (grunt) ->
  fs = require 'fs'
  exec = require('child_process').exec
  stringify = require 'json-stable-stringify'
  require('time-grunt')(grunt)

  grunt.initConfig {
    pkg: grunt.file.readJSON('package.json'),
    coffeelint: {
      options: {
        configFile: 'tools/coffeelint.json'
      },
      unix: ['coffee/*.coffee', 'test/*.coffee', 'tools/*.coffee'],
      win: {
        files: {
          src: ['coffee/*.coffee', 'test/*.coffee', 'tools/*.coffee']
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
        process: (c, s) -> c.replace(/\s/g,'')
      },
      jsonp: {
        src: 'tools/Trove.json',
        dest: 'dist/static/Trove.json.js'
      }
    },
    copy: {
      json: {src: 'tools/Trove.json', dest: 'dist/static/Trove.json', options: process: (c, s) -> c.replace(/\s/g,'')}
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
  grunt.registerTask 'import', 'imports Trove blueprints and generates changelog', (TrovePath) ->
    if TrovePath?
      grunt.task.run "importTroveBlueprints:#{TrovePath.replace('" ','\\ ').replace(':','\\:')}", 'generateTroveChangelogJSON'
    else
      grunt.task.run 'importTroveBlueprints', 'generateTroveChangelogJSON'

  grunt.registerTask 'importTroveBlueprints', 'usage: importTroveBlueprints:TrovePath (excape spaces and : in TrovePath)', (TrovePath) ->
    done = @async()
    global.IO = require './coffee/IO.coffee'
    QubicleIO = require './coffee/Qubicle.io.coffee'
    {Base64IO} = require './coffee/Troxel.io.coffee'
    require './test/TestUtils.coffee'
    if process.platform == 'darwin'
      trovedir = '/Applications/Trion\ Games/Trove-Live.app/Contents/Resources/Trove.app/Contents/Resources'
      delcmd = 'rm -rf qbexport bpexport; mkdir qbexport bpexport'
      devtool = '../MacOS/Trove -tool'
    else
      trovedir = 'C:\\Program Files\\Trove'
      delcmd = 'del /q qbexport\\* bpexport\\* %appdata%\\Trove\\DevTool.log'
      devtool = 'Trove.exe -tool'
    grunt.fail.warn "Can't find Trove folder under specified path." unless grunt.file.isFile trovedir, devtool.split(' ')[0]
    models = {}
    failedBlueprints = []
    repo = process.cwd()
    jsonPath = "#{repo}/tools/Trove.json"
    if TrovePath?
      process.chdir TrovePath.replace('\\ ',' ')
    else
      process.chdir trovedir
    exec delcmd, {timeout: 60000}, (err, stdout, stderr) ->
      throw err if err?
      exec "#{devtool} extractarchive blueprints bpexport & #{devtool} extractarchive blueprints/equipment/ring bpexport", {timeout: 60000}, (err, stdout, stderr) ->
        throw err if err? and (err.killed or err.signal? or err.code != 1) # ignore devtool error code 1
        fs.readdir 'bpexport', (err, files) ->
          throw err if err?
          toProcess = files.length
          processedOne = ->
            if --toProcess == 0
              grunt.config.set 'changelog.oldModels', require(jsonPath)
              grunt.config.set 'changelog.newModels', models
              fs.writeFile jsonPath, stringify(models, space: '  '), (err) ->
                throw err if err?
                count = Object.keys(models).length
                grunt.log.ok "base64 data of #{count} blueprints successfully written to #{jsonPath}"
                grunt.log.subhead "skipped #{failedBlueprints.length} broken blueprints:"
                grunt.log.writeln " * #{bp}" for bp in failedBlueprints
                grunt.log.writeln "cleaning up (could take a minute)..."
              exec delcmd, {timeout: 180000}, (err, stdout, stderr) ->
                throw err if err?
                grunt.log.ok "finished cleaning up qbexport and bpexport"
                process.chdir repo
                done()
          processSny = ->
            f = files.pop()
            return unless f? # all files processed
            if f.length > 10 and f.indexOf('.blueprint') == f.length - 10
              exp = f.split(/\/|\\/).pop() # support both unix and windows style paths
              exp = exp.substring(0, exp.length - 10)
              exec "#{devtool} copyblueprint -generatemaps 1 bpexport/#{f} qbexport/#{exp}.qb", {timeout: 15000}, (err, stdout, stderr) ->
                if err? and (err.killed or err.signal? or err.code != 1) # ignore devtool error code 1
                  failedBlueprints.push(f)
                  processedOne()
                  grunt.log.errorlns "#{toProcess} bp left: skipped #{f} because of trove devtool not responding"
                  return setImmediate processSny
                qbf = 'qbexport/' + exp
                io = new QubicleIO m: qbf + '.qb', a: qbf + '_a.qb', t: qbf + '_t.qb', s: qbf + '_s.qb', ->
                  [x, y, z, ox, oy, oz] = io.computeBoundingBox()
                  io.resize x, y, z, ox, oy, oz
                  models[exp] = new Base64IO(io).export(true, 2)
                  grunt.log.writelns  "#{toProcess} bp left: #{f} done"
                  processedOne()
                setImmediate processSny
            else
              processedOne()
              grunt.log.errorlns "#{toProcess} bp left: skipped #{f} because not a blueprint\n"
              setImmediate processSny
          processSny() for i in [0...2*require('os').cpus().length] by 1

  grunt.registerTask 'loadGitChangelogData', 'usage: loadGitChangelogData:oldsha[:newsha] (newsha defaults to HEAD)', (oldsha, newsha) ->
    done = @async()
    t = false
    grunt.fail.warn 'now gitsha passed: usage: loadGitChangelogData:oldsha[:newsha] (newsha defaults to HEAD)' unless oldsha?
    exec "git show #{oldsha}:tools/Trove.json", {timeout: 10000, maxBuffer: 104857600}, (err, stdout, stderr) ->
      throw err if err?
      grunt.config.set 'changelog.oldModels', JSON.parse stdout.toString()
      done() if t
      t = true
    unless newsha?
      grunt.config.set 'changelog.newModels', require('./tools/Trove.json')
      t = true
    else
      exec "git show #{newsha}:tools/Trove.json", {timeout: 10000, maxBuffer: 104857600}, (err, stdout, stderr) ->
        throw err if err?
        grunt.config.set 'changelog.newModels', JSON.parse stdout.toString()
        done() if t
        t = true

  grunt.registerTask 'generateTroveChangelogJSON', 'usage: generateTroveChangelogJSON[:dateString]
                      (requires either importTroveBlueprints or loadGitChangelogData to be run beforehand)', (date)->
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
