module.exports = (grunt) ->
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
  grunt.registerTask 'lint', -> grunt.task.run if process.platform == 'win32' then 'coffeelint:win' else 'coffeelint:unix'
  grunt.registerTask 'mocha', 'mochaTest'
  grunt.registerTask 'serve', ['build', 'concurrent:serve']
