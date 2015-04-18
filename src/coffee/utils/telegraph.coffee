_ = require 'lodash'
debug = require('debug') 'raconteur:telegraph'
telepath = require './telepath'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

telegraph = (name, template, post, opts)->
    opts = _.assign {
        sugar: false
        file: false
        raw: true
    }, opts
    opts.promise = true
    if opts.raw? and opts.raw
        opts.file = false
        opts.raw = true
    if opts.file and !opts.raw
        opts.raw = !opts.file
    chain = telepath.chain()
    if opts.raw? and opts.raw
        chain.raw()
    if opts.sugar? and opts.sugar
        chain.sugar()
    if opts.promise
        chain.promise()
    conversionOp = chain.post post
                        .template name, template
    d = new Deferred()
    good = (item)->
        d.resolve _.first item
    bad = (e)->
        d.reject e
    conversionOp.ready().then good, bad
    return d

module.exports = telegraph