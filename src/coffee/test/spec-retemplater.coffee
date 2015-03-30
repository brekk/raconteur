assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
retemplater = require cwd + '/lib/retemplater'
fixteur = require cwd + '/test/fixtures/retemplater.json'
chalk = require 'chalk'
path = require 'path'
(()->
    "use strict"
    $ = retemplater
    try
        harness = (method)->
            if fixteur.tests[method]?
                return fixteur.tests[method]
            console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/retemplater.json file?"
            return null
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

            describe '.convertFile', ()->
                xit "should in (jit)-mode allow for the conversion of just-in-time files which are read at runtime", ()->
                xit "should in (jit)-mode be able to inflate the templates with content", ()->
                xit "should in (inline)-mode allow for the conversion of jade files to js templates", ()->
                xit "should in (inline)-mode be able to inflate the templates with content", ()->
                xit "should in (inline-convert)-mode allow for the conversion of sugar (jade & dust) files to js templates", ()->

            describe 'export', ()->
                xit "should be able to generate raw files which contain external templates", ()->

            # describe ".getPostScript", ()->
            # describe ".getPreScript", ()->
            # describe ".readFile", ()->
            # describe ".exportFile", ()->
    catch e
        console.warn "Error during retemplating spec: ", e
        if e.stack?
            console.warn e.stack
    
)(retemplater)