"use strict"

_ = require 'lodash'
promise = require 'promised-io/promise'
Deferred = promise.Deferred
fs = require 'fs'

module.exports = Spool = {}

___ = require('parkplace').scope Spool

___.secret '_files', {}

if Object?.defineProperty?
    Object.defineProperty Spool, 'files', {
        get: ()->
            return _ @_files
    }, {
        writable: false
        enumerable: true
        configurable: false
    }

___.readable 'add', ()->
    self = @
    _(arguments).toArray().each (arg)->
        if _.isString arg
            self._files[arg] = {
                raw: null
            }

___.readable 'remove', ()->
    if 0 < _.size arguments
        self = @
        _(arguments).toArray().each (arg)->
            if self._files[arg]?
                delete self._files[arg]
            return
        return @_files

___.guarded 'readFile', (input, opts={})->
    d = new Deferred()
    unless input?
        d.reject new Error "Expected input to be defined."
    else
        options = _.assign {charset: 'utf8'}, opts
        fs.readFile input, options, (e, read)->
            if e?
                d.reject e
                return
            d.resolve read.toString()
    return d

___.readable 'resolve', ()->
    self = @
    resolver = new Deferred()
    # map the files into an instruction set
    instructions = @files.map((data, file)->
        return ()->
            d = new Deferred()
            success = (x)->
                unless data.raw?
                    self._files[file].raw = x
                d.resolve x
            fail = (x)->
                d.reject x
            unless data.raw?
                self.readFile(file).then success, fail
            return d
    ).value()
    resolve = (content)->
        if content?
            resolver.resolve self.files.map((x)-> return x.raw).value()
    reject = (e)->
        resolver.reject e

    promise.seq(instructions).then resolve, reject
    return resolver