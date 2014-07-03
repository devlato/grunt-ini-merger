module.exports = (grunt) ->
  'use strict'

  grunt.config.init
    pkg: grunt.file.readJSON 'package.json'
    serverOptions:
      load:
        server: '<%= grunt.task.current.args[0] %>'
        paths: [
          # 'conf/config.ini'
          'conf/config.local.ini'
          'conf/config.local.<%= serverOptions.load.server %>.template.ini'
        ]
        resultPath: 'conf/deploy-test-config.ini'
        mergeHierarchy: [
          # 'conf/config.ini'
          'conf/config.local.ini'
          'conf/config.local.<%= serverOptions.load.server %>.template.ini'
        ]

  grunt.loadTasks 'tasks'
  grunt.registerTask 'default', ['serverOptions']
