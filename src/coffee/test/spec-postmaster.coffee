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
        describe 'Postmasteur (a markdown plus front-matter converter)', ()->

            describe '.setPath', ()->
                it 'should set the path value of the Postmaster', (done)->
                    list = harness 'setPath'
                    finish = _.after list.length, done
                    _(list).each (x)->
                        $.setPath(x)
                        $.path.should.equal x
                        finish()
                    return

            # describe '.handleRouting', ()->
            #     it 'should process raw frontmatter'

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

            describe '.readRaw', ()->
                it 'should read a file and return a parsed object', (done)->
                    list = harness 'readRaw'
                    finish = _.after list.length, done
                    _(list).each (content)->
                        $.readRaw content, (e, o)->
                            o.should.be.ok
                            o.attributes.should.be.ok
                            o.content.should.be.ok
                            finish()


            describe '.deliverAsPromise', ()->

    catch e
        console.warn "Error during postman: ", e
        if e.stack?
            console.warn e.stack
    
)(Postmasteur)