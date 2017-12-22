module.exports = function(grunt) {
	var scriptsList = require('./grunt/scriptsList.js');
	var copyrights = grunt.file.readJSON('./gruntConfig/copyrightBanners/copyrights.json');
	var app = {
            // Application variables
			localeJS: 'assets/locales/<%= grunt.config("localName")%>/i18n.js',
			applicationJS: 'app/wtrui_app_<%= grunt.config.get("buildDate") %>.js',
			libraryJS: 'libs/wtrui_lib_<%= grunt.config.get("buildDate") %>.js',
			contextualHelpJS: ['**/WTDesktopHelp/**/Default.js'],
            scripts: scriptsList,
            styles: [
                // css files to be included by includeSource task into index.html
                //'css/font-awesome.css',
                //'css/app_<%= grunt.config.get("buildDate") %>.min.css',
				'css/*.css',
            ]
        };
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        config: {
                  dev: {
                    options: {
                      variables: {
                        'appName': 'LHWTWEB',
                        'environment': 'development',
                        'buildDate': "<%= grunt.template.today('yyyymmddHHMMss') %>",
						'buildVersion': "1.1.0.88",
						'osbBuildVersion': "1.1.0.11",
						'footerVersion':"1.1.0.88",
                        'fontawesomepath': "build/fonts/",
                        'glyphiconspath': "build/fonts/bootstrap/",
						'glyphiconspathCSS': "build/css/fonts/bootstrap/",
						'uiGridFontPath': "build/fonts/",
						'uiGridFontAwesome': "build/fonts/font-awesome/",
						'localName': "en_US"
                      }
                    }
                  },
                  test: {
                    options: {
                      variables: {
                        'appName': 'LHWTWEB',
                        'environment': 'testing',
                        'buildDate': "<%= grunt.template.today('yyyymmddHHMMss') %>",
						'buildVersion': "1.1.0.88",
						'osbBuildVersion': "1.1.0.11",
						'footerVersion':"1.1.0.88",
                        'fontawesomepath': "build/fonts/",
                        'glyphiconspath': "build/fonts/bootstrap/",
						'glyphiconspathCSS': "build/css/fonts/bootstrap/",
						'uiGridFontPath': "build/fonts/",
						'uiGridFontAwesome': "build/fonts/font-awesome/",
						'localName': "en_US"
                      }
                    }
                  },
                  prod: {
                    options: {
                      variables: {
                        'appName': 'LHWTWEB',
                        'environment': 'production',
                        'buildDate': "<%= grunt.template.today('yyyymmddHHMMss') %>",
						'buildVersion': "1.1.0.88",
						'osbBuildVersion': "1.1.0.11",
						'footerVersion':"1.1.0.88",
                        'fontawesomepath': "build/fonts/",
                        'glyphiconspath': "build/fonts/bootstrap/",
						'glyphiconspathCSS': "build/css/fonts/bootstrap/",
						'uiGridFontPath': "build/fonts/",
						'uiGridFontAwesome': "build/fonts/font-awesome/",
						'localName': "en_US"
                      }
                    }
                  }
                },
        app: app,
		sass: {
			dist: {
				options: {
					unixNewlines: true,
					style: 'compressed',
					noCache: true
				},
				files: [{
					expand: true,
					flatten: true,
					src: ['src/assets/css/scss/main.scss'],
					dest: 'build/css/themes/',
					ext: '.css'
				}]
			},
			distmin: {
				options: {
					unixNewlines: true,
					style: 'compressed',
					noCache: true
				},
				files: [{
					expand: true,
					flatten: true,
					src: ['src/assets/css/scss/main.scss'],
					dest: 'build/temp/css/themes/',
					ext: '.css'
				}]
			},
			theme: {
				options: {
					unixNewlines: true,
					style: 'compressed',
					noCache: true
				},
				files: [{
					src: ['src/assets/css/scss/LH/main_LH.scss'],
					dest: 'build/css/themes/main_<%= grunt.option("customer")||"LH"%>.css'
				}]
			},
			thememin: {
				options: {
					unixNewlines: true,
					style: 'compressed',
					noCache: true
				},
				files: [{
					src: ['src/assets/css/scss/LH/main_LH.scss'],
					dest: 'build/temp/css/themes/main_<%= grunt.option("customer")||"LH"%>.css'
				}]
			}
		},
        compass: {
            dist: {
                options: {
                    sassDir: ['src/assets/css/'],
                    cssDir: ['src/assets/css/'],
                }
            }
        },
        cssmin: {
            allCSS: {
                files: {
					'build/css/app_<%= grunt.config.get("buildDate") %>.min.css': ['build/temp/**/*.css','!src/assets/css/themes/*.css'],
                }
            },
			onebyone:{
				files: [{
				  expand: true,
				  cwd: 'build/temp/css',
				  src: ['**/*.css'],
				  dest: 'build/css'
				}]
			}
        },
        clean: {
            build: ["build"],
			temp:["build/temp"],
			js: (function() {
					  var cwd = 'build/';
					  var arr = app.scripts;
					  // determine file order here and concat to arr
					  return arr.map(function(file) {
						return cwd + file;
					  });
					}()),
        },
		concat: {
			options: {
				stripBanners: true,
				separator: ';\n'
			},
			libraryFiles: {
				src:(function() {
					  var cwd = 'src/';
					  var arr = app.scripts;
					  var filteredArray = [];
					  // determine file order here and concat to arr
					  arr.map(function(file) {
						  if(file.indexOf('libs/') != -1){
							  filteredArray.push(cwd + file);
						  }
					  });
					  return filteredArray;
					}()) ,
				dest: 'build/<%= app.libraryJS %>',
			},
			applicationFiles: {
				src:(function() {
					  var cwd = 'src/';
					  var arr = app.scripts;
					  var filteredArray = [];
					  // determine file order here and concat to arr
					  arr.map(function(file) {
						  if(file.indexOf('app/') != -1){
							filteredArray.push(cwd + file);
						  }
					  });
					  return filteredArray;
					}()) ,
				dest: 'build/<%= app.applicationJS %>',
			}
		},
		ngAnnotate:{
			applicationFiles:{
				src:'build/<%= app.applicationJS %>',
				dest: 'build/<%= app.applicationJS %>'
			}
		},
		uglify:{
			options: {
				preserveComments:false,
				mangle: true,
			},
			applicationFiles: {
				src: 'build/<%= app.applicationJS %>' ,
				dest: 'build/<%= app.applicationJS %>',
			},
			libraryFiles: {
				src: 'build/<%= app.libraryJS %>' ,
				dest: 'build/<%= app.libraryJS %>',
			}
		},
        includeSource: {
            // Task to include files into index.html
            options: {
                basePath: 'build',
                baseUrl: '',
                ordering: 'top-down',
				templates: {
				  html: {
					js: '<script src="{filePath}"></script>',
					jsProd: '<script src="{filePath}"></script>',
					css: '<link rel="stylesheet" type="text/css" href="{filePath}" />',
				  }
				}
            },
            app: {
                files: {
                    'build/index.html': 'src/index.grunt.template.html'
                }
            },
			prod:{
				files: {
                    'build/index.html': 'src/index.grunt.prod.template.html'
                }
			}
        },
		sync:{
			appLibJS: { // Another target
                files: [{
                    //expand: true, // Enable dynamic expansion.
                    cwd: 'src/', // Src matches are relative to this path.
                    src: ['**/*.js'], // Actual pattern(s) to match.
                    dest: 'build', // Destination path prefix.
                }, ],
            },
			json: {
                    //JSON data
                    files:[{
                        //expand: true,
                        cwd: 'src',
                        src: ['assets/**/*.json','!assets/css/**/*.json'],
                        dest: 'build/'
                    },]

            },
			html:{
				// modules html templates
                    files:[{
                        //expand: true,
                        cwd: 'src',
                        src: ['app/**/*.html'],
                        dest: 'build/'
                    },]
			}
		},
        copy: {
            main: {
                files: [
                    // images
                    {
                        expand: true,
                        cwd: 'src',
                        src: ['assets/**/*.png'],
                        dest: 'build/'
                    }, {
                        expand: true,
                        cwd: 'src',
                        src: ['assets/**/*.jpg'],
                        dest: 'build/'
                    }, {
                        expand: true,
                        cwd: 'src',
                        src: ['assets/**/*.gif'],
                        dest: 'build/'
                    },
                    {
                      expand: true,
                      cwd: 'WTDesktopHelp',
                      src: ['**/*.*'],
                      dest: 'build/WTDesktopHelp/'
                  },
				  {
                    expand: true,
                    cwd: 'TTKF',
                    src: ['**/*.*'],
                    dest: 'build/TTKF/',
					filter: function (dest) {
						if(grunt.config("isTTKFRequired")){
							return true;
						}
						else{
							return false;
						}
					}
                },
                    // jquery web fonts
                    {
                        src: ['src/libs/fonts/fontawesome-webfont.eot'],
                        dest: '<%=grunt.config.get("fontawesomepath")%>fontawesome-webfont.eot'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.svg'],
                        dest: '<%=grunt.config.get("fontawesomepath")%>fontawesome-webfont.svg'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.ttf'],
                        dest: '<%=grunt.config.get("fontawesomepath")%>fontawesome-webfont.ttf'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.woff'],
                        dest: '<%=grunt.config.get("fontawesomepath")%>fontawesome-webfont.woff'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.woff2'],
                        dest: '<%=grunt.config.get("fontawesomepath")%>fontawesome-webfont.woff2'
                    },
					// jquery web fonts for ui grid
                    {
                        src: ['src/libs/fonts/fontawesome-webfont.eot'],
                        dest: '<%=grunt.config.get("uiGridFontAwesome")%>fontawesome-webfont.eot'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.svg'],
                        dest: '<%=grunt.config.get("uiGridFontAwesome")%>fontawesome-webfont.svg'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.ttf'],
                        dest: '<%=grunt.config.get("uiGridFontAwesome")%>fontawesome-webfont.ttf'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.woff'],
                        dest: '<%=grunt.config.get("uiGridFontAwesome")%>fontawesome-webfont.woff'
                    }, {
                        src: ['src/libs/fonts/fontawesome-webfont.woff2'],
                        dest: '<%=grunt.config.get("uiGridFontAwesome")%>fontawesome-webfont.woff2'
                    },
                    // jquery glyphs fonts///assets/fonts/
                    {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.eot'],
                        dest: '<%=grunt.config.get("glyphiconspath")%>glyphicons-halflings-regular.eot'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.svg'],
                        dest: '<%=grunt.config.get("glyphiconspath")%>glyphicons-halflings-regular.svg'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.ttf'],
                        dest: '<%=grunt.config.get("glyphiconspath")%>glyphicons-halflings-regular.ttf'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.woff'],
                        dest: '<%=grunt.config.get("glyphiconspath")%>glyphicons-halflings-regular.woff'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.woff2'],
                        dest: '<%=grunt.config.get("glyphiconspath")%>glyphicons-halflings-regular.woff2'
                    },
					// jquery glyphs fonts///css/fonts/boostrap
                    {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.eot'],
                        dest: '<%=grunt.config.get("glyphiconspathCSS")%>glyphicons-halflings-regular.eot'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.svg'],
                        dest: '<%=grunt.config.get("glyphiconspathCSS")%>glyphicons-halflings-regular.svg'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.ttf'],
                        dest: '<%=grunt.config.get("glyphiconspathCSS")%>glyphicons-halflings-regular.ttf'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.woff'],
                        dest: '<%=grunt.config.get("glyphiconspathCSS")%>glyphicons-halflings-regular.woff'
                    }, {
                        src: ['src/libs/fonts/glyphicons-halflings-regular.woff2'],
                        dest: '<%=grunt.config.get("glyphiconspathCSS")%>glyphicons-halflings-regular.woff2'
                    },
					{
                        src: ['src/assets/fonts/ui-grid.woff'],
                        dest: '<%=grunt.config.get("uiGridFontPath")%>ui-grid.woff'
                    },
					{
                        src: ['src/assets/fonts/ui-grid.ttf'],
                        dest: '<%=grunt.config.get("uiGridFontPath")%>ui-grid.ttf'
                    },
					{
                        src: ['src/assets/fonts/ui-grid.svg'],
                        dest: '<%=grunt.config.get("uiGridFontPath")%>ui-grid.svg'
                    },
					{
                        src: ['src/assets/fonts/ui-grid.eot'],
                        dest: '<%=grunt.config.get("uiGridFontPath")%>ui-grid.eot'
                    },
                    // modules html templates
                    {
                        expand: true,
                        cwd: 'src',
                        src: ['app/**/*.html'],
                        dest: 'build/'
                    },
                    //JSON data
                    {
                        expand: true,
                        cwd: 'src',
                        src: ['assets/**/*.json','!assets/css/**/*.json'],
                        dest: 'build/'
                    },
					//desmon templates
					{
						flatten: true,
                        expand: true,
                        cwd: 'src',
                        src: ['desmonTemplates/**/*.html'],
                        dest: 'build/'
                    },
					//locale js files
					{
                        expand: true,
                        cwd: 'src',
                        src: ['assets/locales/**/*.js'],
                        dest: 'build/'
					}
                ],
            },
            appLibJS: { // Another target
                files: [{
                    expand: true, // Enable dynamic expansion.
                    cwd: 'src/', // Src matches are relative to this path.
                    src: ['<%= app.scripts %>'], // Actual pattern(s) to match.
                    dest: 'build', // Destination path prefix.
                }, ],
            },
            cssfile: {
                files: [
                  {
					expand:true,
					flatten:true,
					cwd: 'src/',
                    src: ['assets/css/*.css'],
                    dest: 'build/css/'
                  }
              ]
            },
			cssfilemin: {
                files: [
                  {
					expand:true,
					flatten:true,
					cwd: 'src/',
                    src: ['assets/css/*.css'],
                    dest: 'build/temp/css/'
                  }
              ]
            },
            allCSS: {
                files: [
                  {
                    expand: true,
                    cwd: 'src/',
                    src: ['libs/css/*.css'],
                    dest: 'build',
                  },
                  {
                    expand: true,
                    cwd: 'src/',
                    src: ['assets/css/*.css'],
                    dest: 'build',
                  }
              ]
            }
        },
        htmlmin: { // Task
            build: { // Target
                options: { // Target options
                    removeComments: true,
                    collapseWhitespace: true
                },
                files: [{
                    expand: true, // Enable dynamic expansion.
                    cwd: 'build/', // Src matches are relative to this path.
                    src: ['**/*.html'], // Actual pattern(s) to match.
                    dest: 'build/', // Destination path prefix.
                }, ],
            },
            dev: { // Another target
                files: [{
                    expand: true, // Enable dynamic expansion.
                    cwd: 'build/', // Src matches are relative to this path.
                    src: ['**/*.html'], // Actual pattern(s) to match.
                    dest: 'build/', // Destination path prefix.
                }, ],
            }
        },
		replace: {
		  dist: {
			options: {
			  patterns: [
				{
				  match: 'wtruiBuildVersion',
				  replacement: '<%=grunt.config.get("buildVersion")%>'
				},
				{
				  match: 'wtruiFooterVersion',
				  replacement: '<%=grunt.config.get("footerVersion")%>'
				},
				{
				  match: 'wtruiAppName',
				  replacement: '<%=grunt.config.get("appName")%>'
				},
				{
				  match: /(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|]/g,
				  replacement: '../../' + '<%=grunt.config.get("osbBuildVersion")%>' + '/'
				},
				{
				  match: 'wtruiOsbBuildVersion',
				  replacement: '<%=grunt.config.get("osbBuildVersion")%>'
				}
			  ],
			},
			files: [
				{
					expand: true,
					flatten: true,
					src: ['src/app/shared/footer/footer.html'],
					dest: 'build/app/shared/footer/',
				},
				{
					expand: true,
					flatten: true,
					src: ['src/assets/data/urlJson.json'],
					dest: 'build/assets/data/',
				},
				{
					expand: true,
					flatten: true,
					src: ['build/*.html'],
					dest: 'build/',
				}
			]
		  }
		},
        serve: {
            options: {
                port: 9191,
            }
        },
        jasmine: {
            wtrui: {
                src: 'src/**/*.js',
                options: {
                    specs: 'src/test/**/*.js',
                }
            }
        },
        karma: {
            options: {
                configFile: 'src/test/karma.conf.js'
            },
            unit: {
                singleRun: true
            },
            continuous: {
                background: true
            }
        },
         watch: {
                options:
                {
                    interval: 5007, // Added because CPU was constantly running above 80%
                    livereload:35730,
                    dateFormat: function(time) {
                        grunt.log.writeln('The watch finished in ' + time + 'ms at' + (new Date()).toString());
                        grunt.log.writeln('Waiting for more changes...');
                    }
                },
                scripts:{
                    files: ['./src/libs/**/*.js','./src/app/**/*.js','./src/test/**/*.js'],
                    tasks:['config:dev','sync:appLibJS']
                },
                templates:{
                    files:['./src/app/**/*.html'],
                    tasks:['config:dev','sync:html']
                },
				json:{
                    files:['./src/**/*.json'],
                    tasks:['config:dev','sync:json']
                },
                css:{
                    files:['./src/**/*.css'],
                    tasks:['config:dev','copy:cssfile','copy:main']
                },
                scss:{
                    files:['./src/**/*.scss'],
                    tasks:['config:dev','sass:dist','sass:theme','copy:cssfile','copy:main']
                }
        },
		express: {
            all: {
                options:{
                    port:9001,
                    hostname: 'localhost',
                    bases:['./build'],
                    livereload:35730,
                }
            },
			devWithProxy:{
				options:{
                    port:9001,
                    server: './gruntConfig/servers/devProxyServer.js',
                    bases:['./build'],
                    livereload:35730,
                }
			}
       },
      open: {
            all: {
                // Gets the port from the connect configuration
                path: 'http://localhost:<%= express.all.options.port%>',
				// app: "%InternetExplorer%"
            }
      },
      connect: {
            options: {
                port: 9001,
                hostname: 'localhost'
            },
            livereload: {
                options: {
                    //livereload: 35731,
                    open: true,
                    base: ['app']
                }
            },
            test: {
                options: {
                    base: ['app']
                }
            }
        },
		prompt: {
			qabuild: {
			  options: {
				questions: [
				  {
					config: 'isMinificationRequired',
					type: 'confirm',
					message: 'do you want to minify the javascript and css files?',
					default: true
				  },
				  {
					config: 'isTTKFRequired',
					type: 'confirm',
					message: 'do you want to include TTKF contextual help folder into the build?',
					default: false
				  }
				  ,
				  {
					config: 'isAppCacheRequired',
					type: 'confirm',
					message: 'do you want to include App Cache into the build?',
					default: false
				  }
				]
			  }
			}
		},
		manifest:{
			qabuild:{
				options:{
					basePath: 'build/',
					headcomment: " <%= pkg.name %> v<%= grunt.config.get('buildVersion') %>",
					verbose: true,
					timestamp: true,
					hash: true,
					master: ['index.html'],
					cache: ['WTDesktopHelp/Default.js'],
				},
				src:[
					'app/**/*.html',
					'app/**/*.js',
					'libs/**/*.js',
					'assets/locales/**/*.js',
					'css/**/*.css',
					'assets/**/*.json',
					'assets/**/*.gif',
					'assets/**/*.jpg',
                    'assets/**/*.woff', // Added by RP on 10 Sep 2016
					'assets/**/*.png'
				],
				dest:'build/wtrui.appcache'
			}
		},
		locales: {
			options: {
				locales: ['en_US', 'de_DE','zh_CN']
			},
			update: {
				src: [
					'src/app/**/*.html',
					'src/app/**/*.js'
				],
				dest: 'src/assets/locales/{locale}/i18n.json',
				filter: function(src){
					grunt.log.writeln('src file:', src);
					return true;
				}
			},
			build: {
				src: 'src/assets/locales/**/i18n.json',
				dest: 'src/assets/locales/{locale}/i18n.js'
			},
			'export': {
				src: 'src/assets/locales/**/i18n.json',
				dest: 'src/assets/locales/{locale}/i18n.csv'
			},
			'import': {
				src: 'src/assets/locales/**/i18n.csv',
				dest: 'src/assets/locales/{locale}/i18n.json'
			}
		},
		usebanner: {
			copyright: {
			  options: {
				position: 'top',
				banner: "/* \n * Copyright (c) SITA 2016. Confidential. All rights reserved. \n */",

				linebreak: true
			  },
			  files: {
				src: [ 'src/app/**/*.js' ]
			  }
			},
			addSitaCopyright:{
			options: {
				position: 'top',
				banner: copyrights.wtruiSita,
				linebreak: true
			  },
			  files: {
				src: [ 'build/**/custom.css', 'build/**/i18n.js', 'build/<%= app.applicationJS %>' ]
			  }
			},
			addBootStrapSwitchCopyright:{
			options: {
				position: 'top',
				banner: copyrights.wtruiBoostrapSwitch,
				linebreak: true
			  },
			  files: {
				src: [ 'build/**/bootstrap-switch.min.css' ]
			  }
			},
			addLibraryCopyright:{
			options: {
				position: 'top',
				banner: copyrights.wtruiLib,
				linebreak: true
			  },
			  files: {
				src: [ 'build/<%= app.libraryJS %>' ]
			  }
			}
		  }
    });
    // Load the plugin that provides the "concat","uglify","include" task.
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-include-source');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-compass');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    grunt.loadNpmTasks('grunt-contrib-htmlmin');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-jasmine');
    grunt.loadNpmTasks('grunt-karma');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-config');
	grunt.loadNpmTasks('grunt-replace');
    grunt.loadNpmTasks('grunt-express');
    grunt.loadNpmTasks('grunt-open');
	grunt.loadNpmTasks('grunt-ng-annotate');
	grunt.loadNpmTasks('grunt-sync');
	grunt.loadNpmTasks('grunt-sass');
	grunt.loadNpmTasks('grunt-prompt');
	grunt.loadNpmTasks('grunt-manifest');
	grunt.loadNpmTasks('grunt-locales');
	grunt.loadNpmTasks('logfile-grunt');
	grunt.loadNpmTasks('grunt-banner');

	var logfile = require('logfile-grunt');

	grunt.task.registerTask('buildlog', 'Create a new release build log files on each run.', function() {
	  logfile(grunt, { filePath: './gruntBuild.log', clearLogFile: true });
	});

    grunt.registerTask('devbuild', ['clean:build','config:dev','sass:dist','sass:theme','copy:cssfile','copy:appLibJS', /*'cssmin:allCSS', 'clean:temp',*/ 'copy:main', 'includeSource:app','express:all','open','watch']);
	grunt.registerTask('devbuildWithProxy', ['clean:build','config:dev','sass:dist','sass:theme','copy:cssfile','copy:appLibJS', /*'cssmin:allCSS', 'clean:temp',*/ 'copy:main', 'includeSource:app', 'replace','express:devWithProxy','open','watch']);
	//ignore uglify
    grunt.registerTask('testbuild', ['prompt:qabuild','buildwithpromptinput']);
	grunt.registerTask('buildwithpromptinput','perform custom build',function(){
		grunt.log.writeln('isMinificationRequired = ' + grunt.config('isMinificationRequired'));
		grunt.log.writeln('isAppCacheRequired = ' + grunt.config('isAppCacheRequired'));
		if(grunt.config('isMinificationRequired')){
			grunt.task.run(['clean:build','config:test','sass:distmin','sass:thememin','copy:cssfilemin', 'cssmin:onebyone', 'clean:temp', 'copy:main',
			'concat:libraryFiles', 'concat:applicationFiles','ngAnnotate:applicationFiles','uglify:applicationFiles','uglify:libraryFiles',
			'usebanner:addSitaCopyright', 'usebanner:addBootStrapSwitchCopyright', 'usebanner:addLibraryCopyright',
			'includeSource:prod','replace']);
		}
		else{
			grunt.task.run(['clean:build','config:test','sass:dist','sass:theme','copy:cssfile','copy:main', 'concat:libraryFiles', 'concat:applicationFiles',
			'ngAnnotate:applicationFiles',
			'usebanner:addSitaCopyright', 'usebanner:addBootStrapSwitchCopyright', 'usebanner:addLibraryCopyright',
			'includeSource:prod', 'replace']);
		}
		if(grunt.config('isAppCacheRequired')){
			grunt.task.run(['manifest:qabuild']);
		}
	});
	grunt.registerTask('theme', ['clean:build','config:test','sass:theme']);
	grunt.registerTask('unittest',  ['karma:unit']);
	grunt.registerTask('localize',  ['buildlog','locales:update','locales:build','locales:export']);
	grunt.registerTask('localizeimport',  ['locales:import']);
	grunt.registerTask('addcopyright',['usebanner:addSitaCopyright']);
};
