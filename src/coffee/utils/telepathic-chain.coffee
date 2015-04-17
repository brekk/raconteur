_ = require 'lodash'
debug = require('debug') 'raconteur:telegraphic-chain'
crier = require('raconteur-crier').crier
scribe = require 'raconteur-scribe'
promise = require 'promised-io/promise'
Deferred = promise.Deferred
AmpState = require 'ampersand-state'
AmpCollection = require 'ampersand-collection'
chalk = require 'chalk'
slugger = require 'slugger'
debug = require('debug') 'raconteur:telepathic-chain'

postpone = ()->
    d = new Deferred()
    d.yay = _.once d.resolve
    d.nay = _.once d.reject
    return d

InstructionState = AmpState.extend {
    props: {
        fn: ['function', true]
        timestamp: {
            type: 'number'
            required: true
            default: ()->
                return Date.now()
        }
        name: {
            type: 'string'
            required: true
            default: ()->
                return _.uniqueId "instruction"
        }
    }
    session: {
        single: ['function', true]
    }
    wrap: (wrapper)->
        if _.isFunction wrapper
            return _.wrap @fn, wrapper
    initialize: (attrs, opts)->
        if attrs.name?
            attrs.name = _.uniqueId attrs.name
        AmpState::initialize.call @, attrs, opts
        if @fn? and _.isFunction @fn
            @single = _.once @fn
        return @
}

InstructionCollection = AmpCollection.extend {
    model: InstructionState
}

ChainState = AmpState.extend {
    idAttribute: 'name'
    props: {
        # our template list, which contains templates
        templates: ['object', true]
        # our post list, which contains posts
        posts: ['object', true]
        name: {
            type: 'string'
            required: true
            default: ()->
                return _.uniqueId "chain"
        }
    }
    collections: {
        instructions: InstructionCollection
    }
    addInstruction: (name, fn)->
        unless _.isString name
            throw new TypeError "Expected name to be a string."
        unless _.isFunction fn
            throw new TypeError "Expected second parameter to be a function."
        settings = {
            name: name
            fn: fn
        }
        newState = new InstructionState settings
        return @instructions.add newState
    derived: {
        # re-wraps the instruction set so it builds out a hashmap of promises
        commands: {
            deps: [
                'instructions'
            ]
            cache: false
            fn: ()->
                return _.map @instructions.models, (instruction)->
                    if instruction.fn?
                        # return _.wrap instruction.fn, (fn, container)->
                        #     outcome = fn()
                        #     if container? and _.isArray container
                        #         container.push outcome
                        #     return outcome
                        return instruction.single
                    return null
        }
    }
    wrap: (wrapper)->
        unless _.isFunction wrapper
            throw new TypeError "Expected wrapper to be function."
        return _.map @instructions.models, (instruction)->
            if instruction.fn?
                return _.wrap instruction.fn, wrapper
            return null
    initialize: (attrs, opts)->
        if attrs.name?
            attrs.name = _.uniqueId attrs.name
        AmpState::initialize.call @, attrs, opts
        return @
}

sluggable = require('slug')
slug = (str)->
    return sluggable str.toLowerCase()

module.exports = (stateName)->
    "use strict"
    scopeThis = @
    stateSettings = {}
    if stateName?
        stateSettings.name = _.uniqueId stateName
    state = new ChainState stateSettings

    TelepathicChain = {}

    ___ = require('parkplace').scope TelepathicChain

    ___.readable 'id', {
        get: ()->
            return state.getId()
    }, true

    # state object
    ___.guarded "_mode", {
        raw: false # raw is !file
        file: true # file is !raw
        promise: false
        sugar: false
    }

    ___.readable "instructions", {
        get: ()->
            return _(state.instructions.models).sortBy((item)->
                return item.timestamp
            )
    }, true

    # our template list, which contains templates
    ___.guarded '_templates', {}

# our template list, which contains templates
    ___.guarded '_posts', {}

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
            content = "tpChain"
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
    ___.guarded "addInstruction", (name, fn, kind)->
        self = @
        debug "adding instruction", name
        # state.counter += 1
        return state.addInstruction.call state, name, fn, kind

    ___.readable 'lookup', (locAndId)->
        self = @
        d = new Deferred()
        if locAndId?.location? and locAndId?.id?
            out = self[locAndId.location][locAndId.id]
            return out

    # add a post to the 
    ___.readable 'post', (post, options)->
        self = @
        debug "adding instruction to add post"
        self.addInstruction "post", ()->
            debug chalk.green "reading post"
            settings = _.extend self._mode, options
            method = scribe.readFileAsPromise
            if settings.raw? and settings.raw
                method = scribe.readRawAsPromise
            d = new Deferred()
            success = (content)->
                debug "...success"
                if !content? or content.length is 0
                    d.reject new Error "Content is empty, expected content to be a string with length > 0."
                else
                    idName = _.uniqueId slugger content.attributes.title, {smartTrim: 32}
                    self._posts[idName] = content
                    d.resolve {
                        location: '_posts'
                        id: idName
                    }
            fail = (error)->
                debug "...error", error
                d.reject error
            method(post).then success, fail
            return d
        return self

    ___.readable 'template', (name, templateString, options={})->
        self = @
        debug "adding instruction to add template"
        self.addInstruction "template", ()->
            debug chalk.green "reading template"
            settings = _.extend self._mode, options
            d = new Deferred()
            method = crier.loadRawAsPromise
            if self.fileMode
                method = crier.loadFileAsPromise
            templateId = self.generateId()
            success = (content)->
                debug "template:success"
                self._templates[name] = content
                d.resolve {
                    location: '_templates'
                    id: name
                }
                return
            fail = (error)->
                debug "template:error", error
                d.reject error
                return
            method(name, templateString, settings.inflate, settings.sugar).then success, fail
            return d
        return self

    ___.guarded 'hashPromiseArray', (arrayOfFunctionsWhichReturnPromises)->
        d = new Deferred()
        container = {}
        wrappedFunctionList = _.map arrayOfFunctionsWhichReturnPromises, (fn, index)->
            return _.wrap fn, (fx)->
                result = fx()
                container[index] = result
                return result
        bad = (error)->
            d.reject error
        sendContainer = (last)->
            promise.allKeys(container).then (finalOut)->
                d.resolve finalOut
            , (e)->
                d.reject e
        promise.seq(wrappedFunctionList).then sendContainer, bad
        return d

    ___.guarded 'fulfillInstructionsByLookup', (set)->
        self = TelepathicChain
        debug chalk.green set.startOp
        sequentAll = self.hashPromiseArray _.map set.instructions, (struct)->
            return _.wrap struct.single, (fn)->
                subRoute = new Deferred()
                fn().then (out)->
                    out.resolved = self.lookup out
                    subRoute.resolve out
                , (e)->
                    subRoute.reject e
                return subRoute
        return sequentAll

    ___.guarded 'groupByLocation', (item)->
        grouped = _(item).toArray().groupBy('location').value()
        postResolverMap = _.map grouped._posts, (post)->
            post = post.resolved
            groupedTemplatePromises = _.map grouped._templates, (tpl)->
                d = new Deferred()
                tpl = tpl.resolved
                tpl post, (e, out)->
                    if e?
                        debug 'shizza', e
                        d.reject e
                        return
                    debug out
                    d.resolve out
                return d
            return promise.all groupedTemplatePromises
        return postResolverMap

    ___.guarded "execute", ()->
        self = TelepathicChain
        d = postpone()
        bad = (e)->
            d.nay e
            return
        promise.seq(state.commands).then ()->
            # debug chalk.red "templates"
            # debug self._templates
            # debug chalk.green "posts"
            # debug self._posts
            copy = []
            groupByKind = (collection, iter, idx)->
                copy.push iter
                # debug "1", collection
                # debug "2", iter
                # debug "3", idx
                pushNew = (operation)->
                    collection.push
                        startOp: operation
                        operations: [
                            operation
                        ]
                        instructions: [
                            iter
                        ]
                if iter?
                    type = iter.name
                    previousInstruction = copy[idx-1]
                    previousGroup = _.last collection
                    if previousInstruction? and previousGroup?
                        pushToLastGroup = false
                        previousType = _.last previousGroup.operations
                        # arrows = chalk.red "<=>"
                        # debug previousType, arrows, type
                        if (type isnt previousType)
                            if (previousType is previousGroup.startOp)
                                pushToLastGroup = true
                        else
                            if (type isnt previousGroup.startOp)
                                pushToLastGroup = true
                        if pushToLastGroup
                            previousGroup.operations.push type
                            previousGroup.instructions.push iter
                        else
                            pushNew type
                    else
                        pushNew type
                return collection

            reduced = self.instructions.reduce groupByKind, []
            groupedPromises = _.map reduced, self.fulfillInstructionsByLookup
            promise.all(groupedPromises).then (outcomes)->
                flattened = _(outcomes).map(self.groupByLocation).flatten().value()
                promise.all(flattened).then (finalOut)->
                    d.yay _.flatten finalOut
                , bad
                return
            , bad
            return
        , bad
        return d

    ___.readable 'ready', (cb)->
        self = @
        d = new Deferred()
        return self.execute().then (hooray)->
            cb null, hooray
        , (e)->
            cb e
        

    return TelepathicChain