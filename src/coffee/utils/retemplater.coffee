"use strict"

_ = require 'lodash'
debug = require('debug')('raconteur:retemplater')
# debug = console.log
templater = require './templater'
wrapper = require './wrapper'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

fs = require 'fs'
path = require 'path'

# Generate a new copy of the templater with some additional stuff in it
Retemplater = (settings)->
    self = {}
    defaultOptions = {
        input: ''
        output: ''
        sugar: false
        inflate: true
        mode: 'jit' # jit | inline | inline-convert
        spaces: 4
    }
    construct = (opts)->
        options = _.assign defaultOptions, opts
        pwd = process.env.PWD

        if options.sugar?
            options.sugar = !!options.sugar

        if !options.input? or !_.isString(options.input) or !(options.input.length > 0)
            throw new Error 'Expected non-empty input.'
        if !options.output? or !_.isString(options.output) or !(options.output.length > 0)
            throw new Error 'Expected non-empty output.'

        options.input = path.resolve pwd, options.input
        options.output = path.resolve pwd, options.output

        options.inflate = if options.inflate? and options.inflate then options.inflate else false

        self.options = options
        return self

    # escape spaced/indented input as tabs
    self.escapeTabs = (input, spaces)->
        unless spaces?
            spaces = self.options.spaces
        # convert unfriendly sugar to js safe strings
        tabEscape = "[ ]{" + spaces + "}"
        regex = new RegExp tabEscape, 'g'
        return JSON.stringify input.replace regex, "\t"

    # return a postscript to the template file
    self.getPostScript = (input)->
        d = new Deferred()
        (->
            templateName = _.last self.options.input.split '/'
            if self.options.mode is 'jit'
                d.resolve """
                Templateur.loadFileAsPromise("#{self.options.input}", "#{templateName}", #{self.options.inflate});
                }).call(this);
                """
            else if self.options.mode is 'inline'
                escapedInput = self.escapeTabs input
                d.resolve """
                Templateur.add("#{templateName}", #{escapedInput}, #{self.options.sugar});
                }).call(this);
                """
            else if self.options.mode is 'inline-convert'
                templater.convertSugarToDust(input).then (output)->
                    d.resolve """
                    Templateur.add("#{templateName}", #{JSON.stringify(output)});
                    }).call(this);
                    """ 
                , (e)->
                    d.reject e
        )()
        return d 

    self.getPreScript = ()->
        return """
        (function(){
        "use strict"
        """

    # read a file with promises
    self.readFile = (input, opts)->
        d = new Deferred()
        unless input?
            input = self.options.input
        options = _.assign {charset: 'utf8'}, opts
        fs.readFile input, options, (e, read)->
            if e?
                d.reject e
                return
            d.resolve read
        return d

    # export the templater with some new prefixed and postfixed content
    self.exportFile = (input, output, opts)->
        d = new Deferred()
        unless input?
            input = self.options.input
        unless output?
            output = self.options.output
        options = _.assign {charset: 'utf8'}, opts

        fail = (e)->
            d.reject e

        pre = self.getPreScript()

        addPostScript = (file)->
            self.getPostScript file

        wrapFile = (post)->
            templaterFile = path.resolve __dirname, './templater.js'
            wrapper.wrapFileAsPromise templaterFile, pre, post

        addInputFile = ()->
            self.readFile(input, options)

        writeOut = (file)->
            w = new Deferred()
            fs.writeFile output, file, options, (e)->
                if e?
                    w.reject e
                    return
                w.resolve true
                return
            return w

        instructions = [
            addPostScript
            wrapFile
            writeOut
        ]
        unless self.options.mode is 'jit'
            instructions.unshift addInputFile

        promise.seq(instructions).then (done)->
            d.resolve done
        , fail

        return d

    return construct settings


module.exports = Retemplater
