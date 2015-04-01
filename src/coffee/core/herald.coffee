"use strict"

_ = require 'lodash'
debug = require('debug') 'raconteur:herald'
spool = require './spool'

crier = require './crier'
wrapper = require './wrapper'
promise = require 'promised-io/promise'
Deferred = promise.Deferred
path = require 'path'

module.exports = Retemplater = {}

___ = require('parkplace').scope Retemplater

___.secret 'spool', spool

___.secret 'files', {
    get: ()->
        return spool.files
    set: (x)->
        return spool._files = x
}, true

___.readable 'add', ()->
    self = @
    spool.add.apply spool, arguments
    return self

___.readable 'remove', ()->
    self = @
    spool.remove.apply spool, arguments
    return self

# escape spaced/indented input as tabs
___.constant 'escapeTabs', (input, spaces=4)->
    # convert unfriendly sugar to js safe strings
    tabEscape = "[ ]{" + spaces + "}"
    regex = new RegExp tabEscape, 'g'
    return JSON.stringify input.replace regex, "\t"

___.constant 'convertFile', (templateName, input, mode, inflate, sugar, spaces)->
    self = @
    d = new Deferred()
    (->
        if mode is 'jit'
            d.resolve """
            Templateur.loadFileAsPromise("#{input}", "#{templateName}", #{inflate});
            """
        else if mode is 'inline'
            escapedInput = self.escapeTabs input, spaces
            d.resolve """
            Templateur.add("#{templateName}", #{escapedInput}, #{sugar});
            """
        else if mode is 'inline-convert'
            Crier.convertSugarToDust(input).then (output)->
                d.resolve """
                Templateur.add("#{templateName}", #{JSON.stringify(output)});
                """ 
            , (e)->
                d.reject e
        else
            d.reject "Expected mode to be one of ('jit', 'inline', or 'inline-convert')."
    )()
    return d

___.constant 'preWrap', _.once ()->
    return """
    (function(){
    "use strict"
    """

___.constant 'postWrap', _.once ()->
    return "}).call(this);"

___.readable 'export', (opts={})->
    self = @
    exportPromise = new Deferred()

    options = _.assign {
        charset: 'utf8'
        sugar: false
        inflate: true
        mode: 'jit' # jit | inline | inline-convert
        spaces: 4
    }, opts

    fail = (e)->
        exportPromise.reject e

    pre = @preWrap()
    carrier = ""
    post = @postWrap()

    createConvertFileList = (files)->
        console.log "files", files
        return _(files).map((file, fileName)->
            fileSource = file.raw
            fileName = path.basename fileName
            return (lastFile)->
                if lastFile?
                    carrier += "\n" + lastFile
                converted = self.convertFile fileName, fileSource, options.mode, options.inflate, options.sugar, options.spaces
                return converted
        ).value()

    originalCrier = path.resolve __dirname, './crier.js'

    wrapFile = (lastFile)->
        if lastFile?
            carrier += "\n" + lastFile
        # console.log "convertedfiles", convertedFiles, "<<<<", typeof convertedFiles
        post = carrier + "\n" + post
        wrapper.wrapFileAsPromise originalCrier, pre, post

    succeed = (done)->
        exportPromise.resolve done

    spool.resolve().then (files)->
        instructions = createConvertFileList spool.files.value()
        instructions.push wrapFile
        promise.seq(instructions).then succeed, fail

    return exportPromise
