_ = require 'lodash'
promise = require 'promised-io/promise'
wrapstream = require 'wrap-stream'
Deferred = promise.Deferred
fs = require 'fs'

Wrapper =
    wrap: (input, prescript='', postscript='')->
        if !_.isString(input) or !(input.length > 0)
            throw new Error "Expected input to be a non-empty string."
        output = [input]
        if _.isString(prescript) and prescript.length > 0
            output.unshift prescript
        if _.isString(postscript) and postscript.length > 0
            output.push postscript
        return output.join '\n'

    wrapFile: (file, prescript='', postscript='', callback, opts)->
        self = @
        if !_.isFunction callback
            throw new TypeError "Expected callback to be a function."
        args = _.toArray arguments
        if args.length is 3 and _.isFunction postscript
            prescript = args[1]
            callback = postscript
            postscript = null
        if !prescript? or !postscript?
            callback new Error "Expected to be given either prescript or postscript or both."
        if prescript? and !_.isString prescript
            callback throw new Error "Expected prescript to be a string."
        if postscript? and !_.isString postscript
            callback throw new Error "Expected postscript to be a string."
        options = _.assign {charset: 'utf8'}, opts
        fs.readFile file, options, (e, out)->
            if e?
                callback e
                return
            outcome = self.wrap out.toString(), prescript, postscript
            callback null, outcome
        return

    wrapFileAsPromise: (file, prescript='', postscript='', opts=null)->
        d = new Deferred()
        handler = (e, out)->
            if e?
                d.reject e
                return
            d.resolve out
            return
        args = [file, prescript]
        # because postscript is conditional in wrapFile, we should use the same
        # leniency here
        if _.isString postscript
            args.push postscript
        args.push handler
        args.push opts
        @wrapFile.apply @, args
        return d

    wrapStream: (stream, prescript=null, postscript=null, opts=null, endpipe=null)->
        try
            if _.isString stream
                stream = fs.createReadStream stream, opts
            out = if endpipe? then endpipe else process.stdout
            stream.pipe wrapStream prescript, postscript
                  .pipe out
            return
        catch e
            console.log "Error during stream wrapping", e
            if e.stack?
                console.log e.stack

module.exports = Wrapper