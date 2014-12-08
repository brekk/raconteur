_ = require 'lodash'
marked = require './marked-renderer'
frontmatter = require 'json-front-matter'

module.exports = Postman = {}

___ = require('parkplace').scope Postman

___.secret 'path', ''

___.secret 'renderer', false

___.open 'address', (path)->
    if _.isString path
        @path = path
    return @

___.open 'box', (renderer)->
    if _.isFunction renderer
        @renderer = renderer 
    return @

___.open 'deliver', (file, renderer, cb)->
    try
        if @path isnt ''
            file = @path + path
        if @renderer? and _.isFunction(@renderer) and _.size(arguments) is 2
            cb = renderer
            renderer = @renderer
        unless _.isFunction renderer
            if @renderer? and _.isFunction @renderer
                renderer = @renderer
        unless _.isFunction renderer
            throw new TypeError "Expected a renderer function to be given."
        unless _.isFunction cb
            throw new TypeError "Expected a callback function to be given."
        frontmatter.parseFile file, (err, frontdata)->
            if err
                cb err
            unless frontdata?
                throw new Error "Expected data from FrontMatter. Have you added {{{metadata}}} to your post?"
            {body, attributes} = frontdata
            output = marked body
            if output?
                post = {
                    model: {
                        attributes: attributes
                        content: output
                        raw: body
                    }
                }
                renderPromise = renderer post
                renderPromise.then (converted)->
                    cb null, converted
                , (e)->
                    console.log "Error during rendering:", e
                    cb e
                return
            cb new Error "No output."
            return
        return @
    catch e
        console.error "Error during delivery: ", e
        if e.stack?
            console.log e.stack
        cb e