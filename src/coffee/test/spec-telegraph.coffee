# assert = require 'assert'
# should = require 'should'
# _ = require 'lodash'
# cwd = process.cwd()
# postbundler = require cwd + '/lib/postbundler'
# fixteur = require cwd + '/test/fixtures/postbundler.json'
# chalk = require 'chalk'
# path = require 'path'
# (($)->
#     "use strict"
#     try
#         harness = (method)->
#             if fixteur.tests[method]?
#                 return fixteur.tests[method]
#             console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/postbundler.json file?"
#             return null
        
#     catch e
#         console.warn "Error during retemplating spec: ", e
#         if e.stack?
#             console.warn e.stack
    
# )(postbundler)