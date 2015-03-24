"use strict"

_ = require 'lodash'
debug = require('debug')('raconteur:retemplater:cli')
# debug = console.log
Retemplater = require './retemplater'
opts = require('optimist') process.argv.slice 2

fs = require 'fs'
path = require 'path'

defaultOptions = {
    input: ''
    output: ''
    sugar: false
    inflate: true
    jit: false
    spaces: 4
}
options = _.assign defaultOptions, opts
pwd = process.env.PWD

if options._.length is 2 and !_.contains _.keys(opts), 'input'
    options.input = options._[0]
    options.output = options._[1]

if options.sugar?
    options.sugar = !!options.sugar

if !options.input? or !_.isString(options.input) or !(options.input.length > 0)
    throw new Error 'Expected non-empty input.'
if !options.output? or !_.isString(options.output) or !(options.output.length > 0)
    throw new Error 'Expected non-empty output.'

options.input = path.resolve pwd, options.input
options.output = path.resolve pwd, options.output

r = new Retemplater options
r.exportFile().then ()->
    console.log "Successfully wrote file to #{options.output}"
, (e)->
    console.log "Something broke!", e