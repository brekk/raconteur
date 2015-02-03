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

Retemplater = (settings)->
    self = @
    defaultOptions = {
        input: ''
        output: ''
        sugar: false
        inflate: true
        jit: false
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

    self.convertTabbedMultiline = (input, spaces)->
        unless spaces?
            spaces = self.options.spaces
        # convert unfriendly sugar to js safe strings
        tabEscape = "[ ]{" + spaces + "}"
        regex = new RegExp tabEscape, 'g'
        return JSON.stringify input.replace regex, "\t"

    self.getPostScript = (input)->
        templateName = _.last self.options.input.split '/'
        if self.options.jit
            return """
            Templateur.loadFileAsPromise("#{self.options.input}", "#{templateName}", #{self.options.inflate});
            }).call(this);
            """
        else
            escapedInput = self.convertTabbedMultiline input
            return """
            Templateur.add("#{templateName}", #{escapedInput}, #{self.options.sugar});
            }).call(this);
            """

    self.getPreScript = ()->
        return """
        (function(){
        "use strict"
        """

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

    self.exportFile = (input, opts)->
        d = new Deferred()
        unless input?
            input = self.options.input
        options = _.assign {charset: 'utf8'}, opts

        fail = (e)->
            d.reject e

        pre = self.getPreScript()

        addPostScript = (file)->
            p = new Deferred()
            (->
                try
                    p.resolve self.getPostScript file.toString()
                catch e
                    p.reject e
            )()
            return p

        wrapFile = (post)->
            templaterFile = path.resolve __dirname, './templater.js'
            wrapper.wrapFileAsPromise templaterFile, pre, post

        addInputFile = ()->
            self.readFile(input, options)

        instructions = [
            addPostScript
            wrapFile
        ]
        unless self.options.jit
            instructions.unshift addInputFile

        promise.seq(instructions).then (done)->
            d.resolve done
        , fail

        return d



    return construct settings


module.exports = Retemplater
