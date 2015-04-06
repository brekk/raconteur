_ = require 'lodash'
debug = require('debug') 'raconteur:telegraphic-chain'
crier = require('raconteur-crier').crier
scribe = require 'raconteur-scribe'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

sluggable = require('slug')
slug = (str)->
    return sluggable str.toLowerCase()

module.exports = TelepathicChain = {}

___ = require('parkplace').scope TelepathicChain

# state object
___.guarded "_mode", {
    raw: false # raw is !file
    file: true # file is !raw
    promise: false
    sugar: false
}

# our command list, which gets fed promises and resolves when exportAsPromise is called
___.guarded '_instructions', {}

# throw the instructions out with a lodash wrapper
___.guarded 'instructions', {
    get: ()->
        return _(@_instructions).sortBy()
}, true

# our template list, which contains templates
___.guarded '_templates', {}

# throw the templates out with a lodash wrapper
___.guarded 'templates', {
    get: ()->
        return _(@_templates)
}, true

# our post list, which contains posts
___.guarded '_posts', {}

# throw the posts out with a lodash wrapper
___.guarded 'posts', {
    get: ()->
        return _(@_posts)
}, true

# we may need to generate random ids, this does that
___.guarded 'generateId', ()->
    return Date.now()

# set the mode as promise
___.readable "promise", {
    set: (value)->
        @_mode.promise = !!value
}, true

# when raw is true, file is false
setRawOrFileMode = (value)->
    isFileMode = !!value
    if isFileMode
        @_mode.raw = false
        @_mode.file = true
    else
        @_mode.raw = true
        @_mode.file = false
    return @

getFileMode = ()->
    return !!@_mode.file

# accessor & mutator
___.readable "fileMode", {
    set: _.bind setRawOrFileMode, TelepathicChain
    get: _.bind getFileMode, TelepathicChain
}, true

# set the mode to raw (!file)
___.readable "raw", ()->
    @fileMode = false
    return @

# set the mode to file (!raw)
___.readable "file", ()->
    @fileMode = true
    return @

# set the promise mode to true
___.readable "promise", ()->
    @_mode.promise = true
    return @

# add functions to the instruction chain
___.guarded "addInstruction", (ts, fn)->
    self = @
    unless _.isFunction fn
        throw new TypeError "Expected given param to be a function."
    unless _.isNumber ts
        throw new TypeError "Expected timestamp to be a number."
    self._instructions ts, fn

# add a post to the 
___.readable 'post', (post, options)->
    self = @
    args = _.toArray arguments
    
    settings = _.extend self._mode, opts
    if !_.isFunction cb
        throw new TypeError "Expected callback to be a function."
    method = scribe.readFileAsPromise
    if settings.raw? and settings.raw
        method = scribe.readRawAsPromise
    postId = self.generateId()
    d = new Deferred()
    success = (content)->
        self.addInstruction postId, ()->
            if !content?
                d.reject e
            else
                self._posts[postId] = content
                d.resolve content
            return d
    fail = (error)->
        self.addInstruction postId, (error)->
            d.reject error
            return d
    method(post).then success, fail
    return self

___.readable 'template', (name, templateString, options={})->
    self = @
    settings = _.extend self._mode, options
    d = new Deferred()
    method = crier.loadRawAsPromise
    if self.fileMode
        method = crier.loadFileAsPromise
    templateId = self.generateId()
    success = (content)->
        self.addInstruction templateId, ()->
            self._templates[name] = content
            d.resolve content
            return
    fail = (error)->
        self.addInstruction templateId, ()->
            d.reject error
            return
    method(name, templateString, settings.inflate, settings.sugar).then success, fail
    return self

___.guarded "execute", ()->
    self = @
    return promise.seq(self._instructions)

___.readable 'export', (cb)->
    self = @
    succeed = (content)->
        cb null, content
    fail = (e)->
        cb e
    if !!self._mode.promise
        return @execute()
    else
        @execute().then succeed, fail
