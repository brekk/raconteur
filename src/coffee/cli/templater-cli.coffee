"use strict"

_ = require 'lodash'
debug = require('debug')('raconteur:retemplater:cli')
# debug = console.log
Retemplater = require './retemplater'
opts = require('minimist') process.argv.slice 2

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

# inflateFile = if options.inflate? and options.inflate then options.inflate else false

# debug "Options:"
# _(options).each (opt, name)->
#     debug " -> %s: %s", name, opt
# debug "Current working directory:", pwd

# #templateName = null
# #if inflateFile? and inflateFile
# templateName = _.last options.input.split '/'

# debug "templater.loadFileAsPromise %s, %s, %s",  options.input, templateName, inflateFile

# pre = """
# (function(){
# "use strict"
# """
# postJIT = """
# Templateur.loadFileAsPromise("#{options.input}", "#{templateName}", #{inflateFile});
# }).call(this);
# """

# if options.jit
#     post = postJIT
#     return callExport pre, post
# else
#     fs.readFile options.input, {charset:"utf8"}, (e, data)->
#         if e
#             throw e
#         # convert unfriendly sugar to js safe strings
#         tabEscape = "[ ]{" + options.spaces + "}"
#         regex = new RegExp tabEscape, 'g'
#         readInput = JSON.stringify data.toString().replace regex, "\t"

#         postAIO = """
# Templateur.add("#{templateName}", #{readInput}, #{options.sugar});
# }).call(this);
# """
#         post = postAIO
#         return callExport pre, post

# callExport = (pre, post)->

#     exportPromise = templater.export pre, post

#     success = (out)->
#         debug "It all worked.", out
#         if options.output
#             fs.writeFile options.output, out, 'utf8', (done)->
#                 console.log "huh?", arguments
#                 debug "File written to #{options.output}."
#                 process.exit()
#         else
#             process.stdout.write toWrite
#             process.exit()

#     failure = (e)->
#         console.error e
#     exportPromise.then success, failure

r = new Retemplater options
console.log "RETEMPLATOR", r
r.exportFile().then ()->
    console.log "HOORAY", arguments
, (e)->
    console.log "no no", e
module.exports = r