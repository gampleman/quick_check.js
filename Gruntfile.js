module.exports = function (grunt) {
  'use strict';

  var initConfig;

  require('load-grunt-tasks')(grunt);

  initConfig = {
    karma: {
      options: {
        configFile: 'karma.conf.js',
        client: {
          captureConsole: true,
          useIframe: true
        },
        background: true
      },
      unit: {
        // singleRun: true,
        browsers: ['PhantomJS']
      },
    },

    watch: {
      files: [
        'src/**/*.coffee',
        'spec/**/*.coffee'
      ],
      tasks: ['coffee', 'karma:unit:run']
    },

    coffee: {
      source: {
        files: {'src/jasmine-quick-check.js' : ['src/*.coffee', 'src/generators/*.coffee']}
      },
      spec: {
        files: {'spec/quick_check_spec.js': 'spec/quick_check_spec.coffee'}
      }
    },

    concat: {
      dist: {
        src:  ['src/jasmine-quick-check.js'],
        dest: 'dist/jasmine-quick-check.js'
      }

    }

  };

  grunt.registerTask('test', [ 'karma:unit:start', 'watch']);
  grunt.registerTask('dist', ['coffee', 'concat'])

  grunt.initConfig(initConfig);
}
