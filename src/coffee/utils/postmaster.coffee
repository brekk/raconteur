_ = require 'lodash'
promise = require 'promised-io/promise'
Deferred = promise.Deferred
marked = require './renderer'
frontmatter = require 'json-front-matter'

module.exports = Storytelleur = {}

___ = require('parkplace').scope Storytelleur

___.writable 'path', ''

___.open 'setPath', (path)->
    if _.isString path
        @path = path
    return @

___.guarded 'handleFrontMatter', (frontdata, cb)->
    try
        unless frontdata?
            throw new Error "Expected data from FrontMatter. Have you added {{{metadata}}} to your post?"
        {body, attributes} = frontdata
        output = marked body
        callbackable = cb? and _.isFunction cb
        if output?
            post = {
                attributes: attributes
                content: output
                # raw: body
            }
            if callbackable
                cb null, post
                return
        else if callbackable
            cb new Error "Improper markdown conversion."
    catch e
        console.log "Error during handling of frontmatter", e
        if e.stack?
            console.log e.stack
        if cb?
            cb e

___.open 'readRaw', (raw, cb)->
    try
        if !cb? or !_.isFunction cb
            throw new TypeError "Expected callback to be a function."
        parsed = frontmatter.parse raw
        @handleFrontMatter parsed, cb
    catch e
        console.error "Error during readRaw:", e
        if e.stack?
            console.log e.stack
        if cb? and _.isFunction cb
            cb e
    

___.open 'readFile', (file, cb)->
    try
        self = @
        if !cb? or !_.isFunction cb
            throw new TypeError "Expected callback to be a function."
        frontmatter.parseFile file, (err, frontdata)->
            if err
                cb err
                return
            self.handleFrontMatter frontdata, cb
            return
        return @
    catch e
        console.error "Error during readFile: ", e
        if e.stack?
            console.log e.stack
        if cb? and _.isFunction cb
            cb e

___.open 'readRawAsPromise', (raw)->
    d = new Deferred()
    @readRaw raw, (err, data)->
        if err?
            d.reject err
            return
        d.resolve data
    return d

___.open 'readFileAsPromise', (file)->
    d = new Deferred()
    @readFile file, (err, data)->
        if err?
            d.reject err
            return
        d.resolve data
    return d