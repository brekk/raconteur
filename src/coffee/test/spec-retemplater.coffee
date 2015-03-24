assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
Retemplater = require cwd + '/lib/retemplater'
fixteur = require cwd + '/test/fixtures/retemplater.json'
chalk = require 'chalk'
path = require 'path'
(()->
    "use strict"
    $ = null
    try
        harness = (method)->
            if fixteur.tests[method]?
                return fixteur.tests[method]
            console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/retemplater.json file?"
            return null
        beforeEach ()->
            $ = new Retemplater {
                input: ' '
                output: ' '
            }
        describe "Retemplateur", ()->
            describe ".escapeTabs", ()->
                it "should converted unescaped strings to tab-escaped strings", (done)->
                    data = harness 'escapeTabs'
                    size = _.size(data)
                    finish = _.after size, done
                    _(data).each (item)->
                        transformed = $.escapeTabs item.input
                        transformed.should.equal item.output
                        finish()


            # describe ".getPostScript", ()->
            # describe ".getPreScript", ()->
            # describe ".readFile", ()->
            # describe ".exportFile", ()->
    catch e
        console.warn "Error during retemplating spec: ", e
        if e.stack?
            console.warn e.stack
    
)(Retemplater)