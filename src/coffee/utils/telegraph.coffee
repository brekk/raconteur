_ = require 'lodash'
debug = require('debug') 'raconteur:telegraph'
crier = require './crier'
scribe = require './scribe'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

telegraph = (name, template, content, opts=null)->
    # promise a value
    d = new Deferred()
    # smoke test
    isNonEmptyString = (x)->
        #      '' : true
        # 'sksks' : false
        #      33 : false
        #    null : false
        return x? and _.isString(x) and x.length > 0
    if isNonEmptyString(name) and isNonEmptyString(content) and isNonEmptyString(template)
        defaultOptions = {
            sugar: true
            force: true
        }
        if opts? and _.isObject opts
            opts = _.assign defaultOptions, opts
            debug 'given options:'
        else
            opts = defaultOptions
        # deal with errors
        errorHandler = (e)->
            debug "Error during telegraph: %s", e.toString()
            d.reject e
            if e.stack?
                console.log e.stack
        removeTemplate = ()->
            debug "... removing template: %s", name
            crier.remove name
        addTemplate = ()->
            debug "... adding template: %s", name
            crier.add name, template, opts.sugar
        createPost = ()->
            debug "... creating post"
            scribe.readRawAsPromise content
        createTemplate = (data)->
            debug "... creating template"
            debug data
            modelData = {
                model: data
            }
            crier.createAsPromise name, modelData
        instructions = [
            addTemplate
            createPost
            createTemplate
        ]
        if opts.force
            instructions.unshift removeTemplate
        promise.seq(instructions).then (out)->
            debug "sequence finished!"
            d.resolve out
        , errorHandler
    else
        expectation = 'Expected name, content and template to be non-empty strings.'
        debug expectation
        d.reject new Error expectation
    return d

module.exports = telegraph