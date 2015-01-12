_ = require 'lodash'
Templater = require './templater'
Postmaster = require './postmaster'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

forceCreateNewTemplate = (name, template, content, sugar=true)->
    d = new Deferred()
    if content isnt '' and template isnt ''
        errorHandler = (e)->
            console.log "Error:", e
            d.reject e
            if e.stack?
                console.log e.stack
        removeTemplate = ()->
            # console.log "... removeTemplate"
            Templater.remove name
        addTemplate = ()->
            # console.log "... addTemplate"
            Templater.add name, template, sugar
        createPost = ()->
            # console.log "... createPost", arguments
            Postmaster.readRawAsPromise content
        createTemplate = (data)->
            # console.log "... createTemplate", data
            modelData = {
                model: data
            }
            Templater.createAsPromise name, modelData
        instructions = [
            removeTemplate
            addTemplate
            createPost
            createTemplate
        ]
        promise.seq(instructions).then (out)->
            # console.log "sequence finished... ", out
            d.resolve out
        , errorHandler
    else
        d.reject new Error 'Expected both content and template to be non-empty strings.'
    return d

module.exports = forceCreateNewTemplate