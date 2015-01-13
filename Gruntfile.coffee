module.exports = (grunt) ->
  grunt.initConfig {
    pkg: grunt.file.readJSON('package.json'),
    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          require: 'coffee-script/register',
          timeout: 5000
        },
        src: 'test/*.coffee'
      }
    }
    coffeelint: {
      app: ['coffee/*.coffee', 'test/*.coffee'],
      options: {
        configFile: 'coffeelint.json'
      }
    },
    clean: {
      js: 'js',
      dist: 'dist/*',
      static: 'static'
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
        files: {'static/OrbitControls.min.js': 'bower_components/OrbitControls/index.js'}
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
      json: {src: 'tools/Trove.json', dest: 'static/Trove.json'},
      appcache: {src: 'troxel.appcache', dest: 'dist/troxel.appcache'},
      bs_css: {src: 'bower_components/bootstrap/dist/css/bootstrap.min.css', dest: 'static/bootstrap.min.css'},
      bs_theme: {src: 'bower_components/bootstrap/dist/css/bootstrap-theme.min.css', dest: 'static/bootstrap-theme.min.css'},
      bs_js: {src: 'bower_components/bootstrap/dist/js/bootstrap.min.js', dest: 'static/bootstrap.min.js'},
      catiline: {src: 'bower_components/catiline/dist/catiline.min.js', dest: 'static/catiline.min.js'},
      jquery: {src: 'bower_components/jquery/dist/jquery.min.js', dest: 'static/jquery.min.js'},
      stats: {src: 'bower_components/stats.min/index.js', dest: 'static/stats.min.js'},
      threejs: {src: 'bower_components/threejs/build/three.min.js', dest: 'static/three.min.js'},
      typeahead: {src: 'bower_components/typehead.js/dist/typeahead.bundle.min.js', dest: 'static/typeahead.min.js'},
      dist: {src: 'static/*', dest: 'dist/'}
    }
  }

  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.registerTask 'default', ['mochaTest', 'coffeelint', 'build']
  grunt.registerTask 'mocha', 'mochaTest'
  grunt.registerTask 'test', 'mochaTest'
  grunt.registerTask 'lint', 'coffeelint'
  grunt.registerTask 'build', ['clean', 'coffee', 'uglify', 'jade', 'concat', 'copy']
