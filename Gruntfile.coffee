module.exports = (grunt) ->
  grunt.initConfig {
    pkg: grunt.file.readJSON('package.json'),
    coffeelint: {
      unix: ['coffee/*.coffee', 'test/*.coffee', 'tools/*.coffee'],
      options: {
        configFile: 'tools/coffeelint.json'
      },
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
        files: {'dist/static/troxel.min.js': ['js/IO.js', 'js/Qubicle.io.js', 'js/Magica.io.js', 'js/Zoxel.io.js', 'js/Troxel.io.js', 'js/Renderer.js', 'js/Main.js']}
      },
      controls: {
        options: {banner: '// threejs.org/license\n'},
        files: {'dist/static/js/OrbitControls.min.js': 'bower_components/OrbitControls/index.js'}
      }
      lib: {
        options: {
          mangle: false,
          banner: '/*!\n * libTroxel (https://github.com/chrmoritz/Troxel)\n * Copyright 2014 Christian Moritz\n * ' +
                  'Licensed under GNU LGPL v3.0 (https://github.com/chrmoritz/Troxel/blob/master/LICENSE.txt)\n */\n'
        },
        files: {'dist/static/libTroxel.min.js': ['js/IO.js', 'js/Troxel.io.js', 'js/Renderer.js', 'js/libTroxel.js',
                          'bower_components/threejs/build/three.min.js', 'bower_components/OrbitControls/index.js']}
      }
    },
    jade: {
      compile:{
        files: 'dist/index.html': 'views/index.jade'
      }
    },
    concat: {
      options: {
        banner: 'callback(',
        footer: ');'
      },
      jsonp: {
        src: 'tools/Trove.json',
        dest: 'dist/static/Trove.jsonp'
      }
    },
    copy: {
      json: {src: 'tools/Trove.json', dest: 'dist/static/Trove.json'},
      appcache: {src: 'tools/troxel.appcache', dest: 'dist/troxel.appcache'},
      stats: {src: 'bower_components/stats/index.js', dest: 'dist/static/js/stats.min.js'},
      typeahead: {src: 'bower_components/typehead.js/dist/typeahead.bundle.min.js', dest: 'dist/static/js/typeahead.min.js'}
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
      coffee: {
        files: 'coffee/*',
        tasks: ['coffee', 'uglify:main']
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
      serve: ['watch', 'pages'],
      options: {
        logConcurrentOutput: true
      }
    }
  }

  grunt.loadNpmTasks 'grunt-continue'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-bower-task'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-jekyll-pages'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-concurrent'

  grunt.option 'verbose', true if process.env.CI # no need to initialize Gruntfile verbose

  grunt.registerTask 'default', ['continue:on', 'test', 'continue:off', 'build', 'continue:fail-on-warning']
  grunt.registerTask 'test', ['lint', 'mochaTest']
  grunt.registerTask 'build', ['clean', 'bower', 'coffee', 'uglify', 'jade', 'concat', 'copy']
  grunt.registerTask 'lint', -> grunt.task.run(if process.platform == 'win32' then 'coffeelint:win' else 'coffeelint:unix')
  grunt.registerTask 'mocha', 'mochaTest'
  grunt.registerTask 'serve', 'concurrent:serve'
