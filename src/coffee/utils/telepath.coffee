_ = require 'lodash'
debug = require('debug') 'raconteur:telegraph'
crier = require './crier'
scribe = require './scribe'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

module.exports = Telepath = {
    scribe: scribe
    crier: crier
}

___ = require("parkplace").scope Telepath

___.guarded "_templates", {}

___.guarded "_posts", {}

___.readable "templates", {
    get: ()->
        return _(_.toArray @_templates)
    set: (newTemp)->
        if !_.isArray(newTemp) and _.isObject newTemp
            @_templates = newTemp
}, true

___.readable "posts", {
    get: ()->
        return _(_.toArray @_posts)
    set: (newTemp)->
        if !_.isArray(newTemp) and _.isObject newTemp
            @_posts = newTemp
}, true

# # expects implicit arguments
# ___.guarded "promisify", (methodName)->
#     self = @
#     d = new Deferred()
#     if !_.isFunction(self[methodName])
#         d.reject new Error "Expected to be given an existing method to defer to."
#         return d
#     content = _.first _.rest methodName
#     self[methodName], content, (err, success)->
#         if err?
#             d.reject err
#             return
#         d.resolve success
#     return d

# ___.readable 'addTemplate', (name, template, raw=false)->
#     if raw? and raw
#         crier.add
#     crier.addAsPromise ''

# ___.readable 'addTemplateAsPromise', ()->
#     return @promisify 'addTemplate'

# ___.readable "markupRaw", (name, content, cb)->
#     unless _.isFunction cb
#         throw new TypeError "Expected callback to be a function."
#     @scribe.readRaw content, (error, output)->
#         if error?
#             cb error
#             return
#         cb null, output
#         return

# ___.readable "markupFile", (name, content, cb)->
#     unless _.isFunction cb
#         throw new TypeError "Expected callback to be a function."
#     @scribe.readFile content, (error, output)->
#         if error?
#             cb error
#             return
#         cb null, output
#         return

# ___.readable "markupRawAsPromise", (content)->
#     unless _.isFunction cb
#         throw new TypeError "Expected callback to be a function."
#     @scribe.readRawAsPromise content