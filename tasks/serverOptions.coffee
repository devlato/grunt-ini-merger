'use strict'


_       = require 'underscore'
q       = require 'q'
fs      = require 'fs'
ini     = require 'ini'
extend  = require 'node.extend'
async   = require 'async'


mix = (Class, mixin) ->
  Class.Prototype[name] = method for name, method of mixin
  Class.Prototype


class ServerConfiguration

  defaultOptions:
    source:
      encoding: 'utf-8'
      flag: 'r'
    log: () ->
    mergeHierarchy: []

  constructor: (options) ->
    @setOptions options

  setOptions: (options = {}) =>
    @options = extend true, @defaultOptions, @options, options

  getOptions: () =>
    @options

  prepare: (paths = @getOptions().paths, resultPath = @getOptions().resultPath, mergeHierarchy = @getOptions().mergeHierarchy) =>
    loaded = @__load paths
    deferred = q.defer()
    loaded.then (serverOptions) =>
      if mergeHierarchy?
        configuration =
          _.reduce(
            mergeHierarchy,
            (memo, path) =>
              if serverOptions[path]?
                memo = extend true, memo, serverOptions[path]
            , {})
      else
        configuration = _.reduce(
          serverOptions,
          (memo, server) =>
            memo = extend true, memo, server
          , {})
      flushed = @__flush configuration, resultPath
      deferred.resolve flushed
    deferred.promise

  __load: (paths) =>
    options = @getOptions()
    serverOptions = {}
    deferred = q.defer()
    reads = _.map paths, (path) ->
      (callback) ->
        options.log """Trying to read "#{path}"..."""
        fs.readFile path, options.source, (err, data) ->
          options.log """Trying to parse "#{path}"..."""
          serverOptions[path] = ini.parse data
          callback null
    async.parallel reads, () ->
      deferred.resolve serverOptions
    deferred.promise

  __flush: (configuration, path) =>
    options = @getOptions()
    options.log """Serializing final data..."""
    serialized = ini.stringify configuration
    options.log """Flushing data to #{path}..."""
    fs.writeFileSync path, serialized
    serialized


module.exports = (grunt) ->
  grunt.registerMultiTask 'serverOptions', 'Loads server configuration from file', () ->
    if @args?.length?
      done = @async()
      server = @data.server
      options = extend @data, {log: console.log}
      configuration = new ServerConfiguration options
      configuration.prepare().then (configuration) ->
        console.log configuration
        done()
