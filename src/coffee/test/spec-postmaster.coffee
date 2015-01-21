assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
Postmasteur = require cwd + '/build/postmaster'
fixteur = require cwd + '/test/fixtures/postmaster.json'
chalk = require 'chalk'
path = require 'path'

(($)->
    "use strict"
    try
        reset = ()->
            Postmasteur
        harness = (method)->
            if fixteur.tests[method]?
                return fixteur.tests[method]
            console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/postmaster.json file?"
            return null
        describe 'Postmasteur', ()->

            describe '.readFile', ()->
                it 'should read a file and return a parsed object', (done)->
                    list = harness 'readFile'
                    finish = _.after list.length, done
                    _(list).each (file)->
                        adjustedPath = path.resolve __dirname, file
                        $.readFile adjustedPath, (e, o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()

            describe '.readFileAsPromise', ()->
                it 'should read a file and return a promise which returns a parsed object', (done)->
                    list = harness 'readFile'
                    finish = _.after list.length, done
                    _(list).each (file)->
                        adjustedPath = path.resolve __dirname, file
                        $.readFileAsPromise(adjustedPath).then (o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()
                        , (e)->
                            console.log "There was an error during readFileAsPromise", e
                            if e.stack?
                                console.log e.stack

            describe '.readRaw', ()->
                it 'should read raw content and return a parsed object', (done)->
                    list = harness 'readRaw'
                    finish = _.after list.length, done
                    _(list).each (content)->
                        $.readRaw content, (e, o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()

            describe '.readRawAsPromise', ()->
                it 'should read raw content and return a promise which returns a parsed object', (done)->
                    list = harness 'readRaw'
                    finish = _.after list.length, done
                    _(list).each (content)->
                        $.readRawAsPromise(content).then (o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()
                        , (e)->
                            console.log "There was an error during readRawAsPromise", e
                            if e.stack?
                                console.log e.stack

    catch e
        console.warn "Error during postman: ", e
        if e.stack?
            console.warn e.stack
    
)(Postmasteur)