module.exports = function (grunt) {
  'use strict';

  var initConfig;

  require('load-grunt-tasks')(grunt);

  initConfig = {
    karma: {
      options: {
        client: {
          captureConsole: true,
          useIframe: true
        }
      },
      unit: {
        configFile: 'spec/config/jasmine.conf.js',
        browsers: ['PhantomJS'],
        background: true
      },
      qunit: {
        configFile: 'spec/config/qunit.conf.js',
        browsers: ['PhantomJS'],
        singleRun: true
      },
      jasmine: {
        configFile: 'spec/config/jasmine.conf.js',
        singleRun: true,
        browsers: ['PhantomJS']
      },
      "typescript-mocha": {
        configFile: 'spec/config/typescript-mocha.conf.js',
        singleRun: true,
        browsers: ['PhantomJS']
      }
    },

    watch: {
      files: [
        'src/**/*.coffee',
        'spec/**/*.coffee'
      ],
      tasks: ['coffee', 'regenerator', 'karma:unit:run', 'docs']
    },

    coffee: {
      source: {
        files: {'src/quick-check.es6.js' : ['src/quick_check_library.coffee', 'src/*.coffee', 'src/generators/*.coffee', 'src/integrations/*.coffee']},
        options: {
          bare: true
        }
      },
      spec: {
        files: {
          'spec/jasmine/quick_check_spec.js': 'spec/jasmine/*.coffee',
          'spec/qunit/quick_check_spec.js': 'spec/qunit/*.coffee'
        }
      }
    },

    regenerator: {
      options: {
        includeRuntime: true,
      },
      source: {
        files: {'src/quick-check.js' : ['src/quick-check.es6.js']}
      }
    },

    concat: {
      dist: {
        files: {
          'dist/quick-check.js':  ['src/quick-check.js'],
          'dist/jasmine-quick-check.js': ['src/quick-check.js'],
        },
        options: {
          banner: "(function(){ \n 'use strict';\n",
          footer: "})();"
        }
      },
      docs: {
        src: ['src/quick_check_library.coffee', 'src/generators/basic.coffee', 'src/generators/combinators.coffee', 'src/generators/number.coffee', 'src/generators/array.coffee', 'src/generators/functions.coffee', 'src/generators/object.coffee', 'src/generators/string.coffee', 'src/generators/various.coffee', 'src/shrink.coffee', 'src/integrations/jasmine_extension.coffee'],
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

    ts: {
      default : {
        src: ["**/*.ts", "!node_modules/**/*.ts"],
        tsconfig: true
      }
    },

    'gh-pages': {
        options: {
          base: 'docs'
        },
        publish: {
          options: {
            repo: 'https://github.com/gampleman/quick_check.js.git',
            message: 'publish gh-pages (cli)'
          },
          src: ['**']
        },
        deploy: {
  				options: {
  					user: {
  						name: 'demo-travis-gh-pages',
  						email: 'bartvanderschoor@gmail.com'
  					},
  					repo: 'https://' + process.env.GH_TOKEN + '@github.com/gampleman/quick_check.js.git',
  					message: 'publish gh-pages (auto)' + getDeployMessage(),
  					silent: true
  				},
  				src: ['**']
			  }

      },

      clean: ['docs', 'spec/*.js', 'src/*.js']

  };

  function getDeployMessage() {
		var ret = '\n\n';
		if (process.env.TRAVIS !== 'true') {
			ret += 'missing env vars for travis-ci';
			return ret;
		}
		ret += 'branch:       ' + process.env.TRAVIS_BRANCH + '\n';
		ret += 'SHA:          ' + process.env.TRAVIS_COMMIT + '\n';
		ret += 'range SHA:    ' + process.env.TRAVIS_COMMIT_RANGE + '\n';
		ret += 'build id:     ' + process.env.TRAVIS_BUILD_ID  + '\n';
		ret += 'build number: ' + process.env.TRAVIS_BUILD_NUMBER + '\n';
		return ret;
	}

  grunt.registerTask('check-deploy', function() {
		// need this
		this.requires(['docs']);

		// only deploy under these conditions
		if (process.env.TRAVIS === 'true' && process.env.TRAVIS_SECURE_ENV_VARS === 'true' && process.env.TRAVIS_PULL_REQUEST === 'false') {
			grunt.log.writeln('executing deployment');
			// queue deploy
			grunt.task.run('gh-pages:deploy');
		}
		else {
			grunt.log.writeln('skipped deployment');
		}
	});

  grunt.registerTask('test', [ 'karma:unit:start', 'watch']);
  grunt.registerTask('dist', ['coffee', 'regenerator', 'concat:dist']);
  grunt.registerTask('docs', ['concat:docs', 'docco:source']);
  grunt.registerTask('release', ['dist', 'docs', 'concat:docs2', 'gh-pages:publish', 'clean']);
  grunt.registerTask('ci', ['coffee', 'regenerator', 'ts', 'karma:jasmine', 'karma:qunit', 'karma:typescript-mocha',  'clean']);
  grunt.registerTask('deploy', 'Publish docs from TravisCI', ['dist', 'docs', 'concat:docs2', 'gh-pages:deploy']);

  grunt.initConfig(initConfig);
}
