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
                return _.map fixteur.tests[method], (loc)->
                    return path.resolve(__dirname, loc)
            console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/spool.json file?"
            return null
        reset = (done)->
            spool._files = {}
            return done()
        beforeEach reset
        describe "Spool", ()->
            describe 'add', ()->
                it "should be able to add unadorned strings as filenames", ()->
                    addTests = harness 'add'
                    out = $.add.apply $, addTests
                    _(addTests).each (test)->
                        _(out).contains(test).should.equal true
            describe 'remove', ()->
                it "should be able to remove unadorned strings as filenames", ()->
                    addTests = harness 'add'
                    out = $.add.apply $, addTests
                    _(addTests).each (test)->
                        _(out).contains(test).should.equal true
                    removeTests = harness 'remove'
                    out = $.remove.apply $, removeTests
                    _(removeTests).each (test)->
                        _(out).contains(test).should.equal false
            describe 'readFile', ()->
                it "should promise to read a given file", (done)->
                    addTests = harness 'add'
                    succeed = (x)->
                        x.should.be.ok
                        done()
                    fail = (e)->
                        e.should.not.be.ok
                        done()
                    $.readFile(addTests[0]).then succeed, fail
            describe 'resolve', ()->
                it "should be able to resolve the filenames and convert them to their raw inputs", (done)->
                    addTests = harness 'add'
                    out = $.add.apply $, addTests
                    _(addTests).each (test)->
                        _(out).contains(test).should.equal true
                    succeed = (x)->
                        x.should.be.ok
                        done()
                    fail = (e)->
                        e.should.not.be.ok
                        done()
                    $.resolve().then succeed, fail
    catch e
        console.warn "Error during spool spec: ", e
        if e.stack?
            console.warn e.stack
    
)(spool)