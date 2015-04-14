_ = require 'lodash'
debug = require('debug') 'raconteur:telegraphic-chain'
crier = require('raconteur-crier').crier
scribe = require 'raconteur-scribe'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

sluggable = require('slug')
slug = (str)->
    return sluggable str.toLowerCase()

module.exports = ()->
    "use strict"

    TelepathicChain = {}

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
            return _(@_instructions).sortBy('timestamp')
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

    # set sugar mode
    ___.guarded '_sugar', {
        get: ()->
            return @_mode.sugar
        set: (value=true)->
            @_mode.sugar = value
            return value
    }, true

    ___.readable 'sugar', ()->
        @_sugar = true

    # we may need to generate random ids, this does that
    ___.guarded 'generateId', (content=null)->
        unless content?
            content = "telepathicChain"
        return _.uniqueId content

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

    # add functions to the instruction chain
    ___.guarded "addInstruction", (name, fn, data={})->
        self = @
        kind = null
        stack = null
        if _.isFunction(name) and _.toArray(arguments).length < 3
            fn = name
            name = null
        if -1 < name?.indexOf ':'
            stack = name.split(':')
            kind = stack[0]
        newName = @generateId name
        unless kind?
            kind = name
        unless _.isFunction fn
            throw new TypeError "Expected given param to be a function."
        command = {
            data: data
            instruction: fn
            timestamp: Date.now()
            id: newName
            kind: kind
        }
        if stack? and stack.length > 0
            command.category = stack
        console.log "self._instructions[", newName, "] =", command
        self._instructions[newName] = command
        return newName

    # add a post to the 
    ___.readable 'post', (post, options)->
        self = @
        args = _.toArray arguments
        
        settings = _.extend self._mode, options
        
        method = scribe.readFileAsPromise
        if settings.raw? and settings.raw
            method = scribe.readRawAsPromise
        postId = self.generateId()
        d = new Deferred()
        success = (content)->
            console.log "post:success"
            self.addInstruction "post:success", ()->
                if !content? or content.length is 0
                    d.reject new Error "Content is empty, expected content to be a string with length > 0."
                else
                    self._posts[postId] = content
                    d.resolve content
                return d
        fail = (error)->
            console.log "post:error", error
            self.addInstruction "post:error", ()->
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
            console.log "template:success"
            self.addInstruction "template:success", ()->
                self._templates[name] = content
                d.resolve content
                return
        fail = (error)->
            console.log "template:error", error
            self.addInstruction "template:error", ()->
                d.reject error
                return
        method(name, templateString, settings.inflate, settings.sugar).then success, fail
        return self

    ___.guarded "execute", ()->
        self = TelepathicChain
        findFirstBeforeExample = (example)->
            unless example?.timestamp?
                throw new Error "Expected example to have a timestamp."
            self.instructions.find((instruction)->
                timeCondition = instruction.timestamp < example.timestamp
                unless timeCondition
                    return false
                categoryMatches = false
                if !example.category? or !instruction.category?
                    return false
                categoryMatches = _.intersection(example.category, instruction.category).length > 0
                return categoryMatches or false
            ).first().value()
        mappedExecutions = self.instructions.groupBy('kind')
        console.log "SELF SELF", self
        console.log "SELF INSTRUCTIONS", self.instructions
        console.log "mappedExecutions", mappedExecutions
        # .map((commandGroup)->
        #     _.each commandGroup, (group, name)->


        # ).compact().value()
        # return promise.seq mappedExecutions

    ___.readable 'export', (cb)->
        self = @
        succeed = (content)->
            cb null, content
        fail = (e)->
            cb e
        if !self._mode.promise
            return self.execute()
        else
            self.execute().then succeed, fail

    return TelepathicChain