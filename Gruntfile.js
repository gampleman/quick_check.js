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
        }

      },
      unit: {
        // singleRun: true,
        browsers: ['PhantomJS'],
        background: true
      },
      continuous: {
        singleRun: true,
        browsers: ['PhantomJS']
      }
    },

    watch: {
      files: [
        'src/**/*.coffee',
        'spec/**/*.coffee'
      ],
      tasks: ['coffee', 'karma:unit:run', 'docs']
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
      },
      docs: {
        src: ['src/quick_check_library.coffee', 'src/generators/basic.coffee', 'src/generators/combinators.coffee', 'src/generators/number.coffee', 'src/generators/array.coffee', 'src/generators/functions.coffee', 'src/generators/object.coffee', 'src/generators/string.coffee', 'src/generators/various.coffee', 'src/jasmine_extension.coffee'],
        dest: 'docs/quick_check.coffee'
      },
      docs2: {
        src: ['docs/quick_check.html'],
        dest: 'docs/index.html'
      }
    },

    docco: {
      source: {
        src: ['docs/quick_check.coffee'],
        options: {
          output: 'docs/'
        }
      }
    },

    'gh-pages': {
        options: {
          base: 'docs'
        },
        src: ['**']
      },

      clean: ['docs', 'spec/*.js', 'src/*.js']

  };

  grunt.registerTask('test', [ 'karma:unit:start', 'watch']);
  grunt.registerTask('dist', ['coffee', 'concat:dist']);
  grunt.registerTask('docs', ['concat:docs', 'docco:source']);
  grunt.registerTask('release', ['dist', 'docs', 'concat:docs2', 'gh-pages', 'clean']);

  grunt.initConfig(initConfig);
}
