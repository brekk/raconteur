assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
spool = require cwd + '/lib/spool'
fixteur = require cwd + '/test/fixtures/spool.json'
chalk = require 'chalk'
path = require 'path'
(()->
    "use strict"
    $ = spool
    try
        harness = (method)->
            if fixteur.tests[method]?
                return fixteur.tests[method]
            console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/spool.json file?"
            return null
        describe "Spool", ()->
            describe 'add', ()->
                xit "should be able to add unadorned strings as filenames", ()->
            describe 'remove', ()->
                xit "should be able to remove unadorned strings as filenames", ()->
            describe 'export', ()->
                xit "should be able to resolve the filenames and convert them to their raw inputs", ()->
    catch e
        console.warn "Error during spool spec: ", e
        if e.stack?
            console.warn e.stack
    
)(spool)