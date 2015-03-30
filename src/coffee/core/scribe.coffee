_ = require 'lodash'
promise = require 'promised-io/promise'
Deferred = promise.Deferred
marked = require './renderer'
frontmatter = require 'json-front-matter'

module.exports = Scribe = {}
debug = require('debug') 'raconteur:scribe'

___ = require('parkplace').scope Scribe

___.secret '_renderer', marked

___.guarded 'setRenderer', (renderer)->
    if renderer? and _.isFunction renderer
        debug 'Setting custom renderer function'
        @_renderer = renderer
    return @

___.guarded 'getRenderer', ()->
    return @_renderer

___.guarded 'handleFrontMatter', (frontdata, cb)->
    try
        unless frontdata?
            throw new Error "Expected data from FrontMatter. Have you added {{{metadata}}} to your post?"
        else
            debug "handling frontmatter data"
            debug frontdata
            if frontdata.body? and frontdata.attributes?
                {body, attributes} = frontdata
                renderer = @getRenderer()
                output = renderer body
                callbackable = cb? and _.isFunction cb
                if output?
                    post = {
                        attributes: attributes
                        content: output
                        # raw: body
                    }
                    if callbackable
                        debug "sending back post", post
                        cb null, post
                        return
            else
                if callbackable
                    cb new Error "Expected frontdata.body and frontdata.attributes."
                return
        if callbackable
            cb new Error "Improper markdown conversion."
    catch e
        debug "Error during handling of frontmatter: %s", e.toString()
        if e.stack?
            console.log e.stack
        if cb?
            cb e

___.open 'readRaw', (raw, cb)->
    try
        if !cb? or !_.isFunction cb
            throw new TypeError "Expected callback to be a function."
        limit = 30
        truncated = raw
        if raw.length > limit
            truncated = raw.substr 0, limit
        debug "Parsing data from raw string: %s", truncated
        parsed = frontmatter.parse raw
        if parsed?
            debug "Successfully parsed."
            @handleFrontMatter parsed, cb
        else
            throw new Error "Nothing parsed from frontmatter."
    catch e
        debug "Error during readRaw: %s", e.toString()
        if e.stack?
            console.log e.stack
        if cb? and _.isFunction cb
            cb e
    

___.open 'readFile', (file, cb)->
    try
        self = @
        if !cb? or !_.isFunction cb
            throw new TypeError "Expected callback to be a function."
        debug "Parsing data from a file: %s", file
        frontmatter.parseFile file, (err, frontdata)->
            if err
                cb err
                return
            debug "Successfully parsed."
            self.handleFrontMatter frontdata, cb
            return
        return @
    catch e
        debug "Error during readFile: %s", e.toString()
        if e.stack?
            console.log e.stack
        if cb? and _.isFunction cb
            cb e

___.open 'readRawAsPromise', (raw)->
    d = new Deferred()
    @readRaw raw, (err, data)->
        if err?
            debug "Error during readRawAsPromise: %s", err.toString()
            d.reject err
            return
        d.resolve data
    return d

___.open 'readFileAsPromise', (file)->
    d = new Deferred()
    @readFile file, (err, data)->
        if err?
            debug "Error during readFileAsPromise: %s", err.toString()
            d.reject err
            return
        d.resolve data
    return d