_ = require 'lodash'
crier = require('raconteur-crier').crier
scribe = require 'raconteur-scribe'
promise = require 'promised-io/promise'
Deferred = promise.Deferred
AmpState = require 'ampersand-state'
AmpCollection = require 'ampersand-collection'
slugger = require 'slugger'
debug = require('debug') 'raconteur:telepathic-chain'
path = require 'path'

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

    ___.guarded '__chain__', 'TELEPATH'

    ___.guarded "_locals", {}

    ___.readable 'locals', {
        get: ()->
            return @_locals
        set: (obj)->
            if !_.isObject obj
                throw new TypeError "Expected .locals assignment to be an object."
            @_locals = obj
    }, true

    # state object
    ___.guarded "_mode", {
        raw: false # raw is !file
        file: true # file is !raw
        promise: false
        sugar: false
        yaml: false # yaml is !json
        json: true # json = !yaml
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
        return @

    # we may need to generate random ids, this does that
    ___.guarded 'generateId', (content=null)->
        unless content?
            content = "tpChain"
        return _.uniqueId content

    # set the mode as promise
    ___.readable "promise", ()->
        @_mode.promise = true
        return @


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

    # when json is true, yaml is false
    setJSONMode = (value)->
        isJSONMode = !!value
        if isJSONMode
            @_mode.yaml = false
            @_mode.json = true
        else
            @_mode.yaml = true
            @_mode.json = false
        return @

    getJSONMode = ()->
        return !!@_mode.json

    getFileMode = ()->
        return !!@_mode.file

    # accessor & mutator
    ___.guarded "fileMode", {
        set: _.bind setRawOrFileMode, TelepathicChain
        get: _.bind getFileMode, TelepathicChain
    }, true

    # accessor & mutator
    ___.guarded "jsonMode", {
        set: _.bind setJSONMode, TelepathicChain
        get: _.bind getJSONMode, TelepathicChain
    }, true

    # set the mode to yaml (!json)
    ___.readable "yaml", ()->
        self = TelepathicChain
        self.jsonMode = false
        return self

    # set the mode to json (!yaml)
    ___.readable "json", ()->
        self = TelepathicChain
        self.jsonMode = true
        return self

    # set the mode to raw (!file)
    ___.readable "raw", ()->
        self = TelepathicChain
        self.fileMode = false
        return self

    # set the mode to file (!raw)
    ___.readable "file", ()->
        self = TelepathicChain
        self.fileMode = true
        return self

    # add functions to the instruction chain
    ___.guarded "addInstruction", (name, fn, kind)->
        self = @
        debug "adding instruction", name
        # state.counter += 1
        return state.addInstruction.call state, name, fn, kind

    ___.readable 'lookup', (location, id)->
        self = @
        out = self[location][id]
        return out

    yamlRegex = /^-{3}/

    # add a post to the 
    ___.readable 'post', (post, options)->
        self = TelepathicChain
        debug "adding instruction to add post"
        self.addInstruction "post", ()->
            debug "reading post"

            settings = _.extend self._mode, options
            if settings.yaml
                debug "...yaml"
                scribe.yaml()
            method = scribe.readFileAsPromise
            if settings.raw? and settings.raw
                method = scribe.readRawAsPromise
                if yamlRegex.test post
                    debug "automatically switching to yaml mode"
                    scribe.yaml()
            d = new Deferred()
            success = (content)->
                debug "...success"
                if !content?
                    d.reject new Error "Content is empty, expected content to be an object."
                else
                    idName = slugger content.attributes.title, {smartTrim: 32}
                    if idName is ''
                        console.log "HOOOOOOOOOOOOOOOOO", content
                        d.reject new Error "idName is empty."
                        return
                    unless self._posts[idName]?
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

    ___.guarded 'resolveFileName', (name)->
        return path.basename name

    ___.readable 'template', (name, templateString, options={})->
        self = TelepathicChain
        debug "adding instruction to add template"
        originalArguments = _.toArray arguments
        self.addInstruction "template", ()->
            debug "reading template"
            settings = _.extend self._mode, options
            d = new Deferred()
            method = crier.loadRawAsPromise
            if self.fileMode
                method = crier.loadFileAsPromise
                # if we had only two arguments, pull the name from the filename
                if (originalArguments.length is 2) and _.isString(name) and _.isObject(templateString)
                    options = templateString
                    templateString = name
                    filename = self.resolveFileName name
                    name = filename
            success = (content)->
                debug "template:success %s", name
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
            method(templateString, name, settings.inflate, settings.sugar).then success, fail
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
        sequentAll = self.hashPromiseArray _.map set.instructions, (struct)->
            subRoute = new Deferred()
            good = (out)->
                out.resolved = self.lookup out.location, out.id
                subRoute.resolve out
            bad = (e)->
                subRoute.reject e
            return _.wrap struct.fn, (fn)->
                fn().then good, bad
                return subRoute
        return sequentAll

    ___.guarded 'addLocalsToContent', (content)->
        self = TelepathicChain
        localized = content
        currentContent = content.content
        stripPostsAndTemplatesFromObj = (obj)->
            if obj.posts?
                delete obj.posts
            if obj.templates?
                delete obj.templates
        _.each self.locals, (loc, key)->
            if (key isnt '$len') and (key isnt '$idx') and (key isnt 'content') and (key isnt 'attributes')
                # if (key is 'posts') or (key is 'templates')
                #     localized[key] = _(loc).map((item)->
                #         if item.content is currentContent
                #             console.log "nuke"
                #             return null
                #         item = stripPostsAndTemplatesFromObj item
                #         return item
                #     ).compact().value()
                # else
                localized[key] = loc
        return localized

    ___.guarded 'resolvePostsAndTemplates', (posts, templates, group)->
        self = TelepathicChain
        return _(posts).map((postContent, key)->
            postIds = _.pluck(group._posts, 'id')
            templateIds = _.pluck(group._templates, 'id')
            if _.contains postIds, key
                groupedTemplatePromises = _(templates).map((tplContent, tplKey)->
                    try
                        unless _.contains templateIds, tplKey
                            return null
                        d = new Deferred()
                        content = postContent
                        localized = self.addLocalsToContent content
                        tplContent localized, (e, out)->
                            if e?
                                d.reject e
                                return
                            d.resolve out
                        return d
                    catch e
                        d.reject e
                        if e.stack?
                            console.log e.stack
                ).compact().value()
                return promise.all groupedTemplatePromises
            return null
        ).compact().value()

    # group by location fn, used during mapping in .execute 
    ___.guarded 'groupByLocation', (item)->
        self = TelepathicChain
        grouped = _(item).toArray().groupBy('location').value()
        output = self.resolvePostsAndTemplates self._posts, self._templates, grouped
        return output

    ___.guarded "execute", ()->
        self = TelepathicChain
        executionDeferred = postpone()
        bad = (e)->
            executionDeferred.nay e
            return
        promise.seq(state.commands).then ()->
            debug "templates", self._templates
            debug "posts", _.map (_.pluck self._posts, 'content'), (f)-> return f.substr(0,32)
            noPosts = !(_.size(self._posts) > 0)
            noTemplates = !(_.size(self._templates) > 0)
            if noPosts or noTemplates
                bad new Error "Expected to be invoked with at least one post and one template."
                return
            # if self.locals?
            #     self.locals.posts = self._posts
            #     self.locals.templates = self._templates
            # we use the copy array as a clipboard for reverse iteration
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
                        # console.log previousType, arrows, type
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
                finalOutcomes = _(outcomes).map(self.groupByLocation).map((mapped)->
                    return promise.all(mapped)
                ).value()
                resolve = (out)->
                    executionDeferred.resolve _.flatten _.flatten out
                if finalOutcomes.length is 1
                    finalOutcomes[0].then resolve, bad
                else
                    promise.all(finalOutcomes).then resolve, bad
            , bad
            return
        , bad
        return executionDeferred

    ___.readable 'ready', (cb)->
        self = @
        d = new Deferred()
        good = (hooray)->
            debug "ready:good", hooray
            cb null, hooray
        bad = (e)->
            debug "ready:bad", e
            cb e
        if !self._mode.promise
            return self.execute().then good, bad
        return self.execute()

    return TelepathicChain