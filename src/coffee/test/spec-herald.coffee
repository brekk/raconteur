assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
herald = require cwd + '/lib/herald'
fixteur = require cwd + '/test/fixtures/herald.json'
chalk = require 'chalk'
path = require 'path'
(()->
    "use strict"
    $ = herald
    try
        harness = (method)->
            if fixteur.tests[method]?
                unless method is 'add'
                    return fixteur.tests[method]
                return _.map fixteur.tests[method], (loc)->
                    return path.resolve __dirname, loc
            console.log chalk.red "No fixture for #{method} found, are you sure you added it to fixtures/herald.json file?"
            return null

        reset = (done)->
            $.files = {}
            return done()

        describe "Herald", ()->
            describe ".add", ()->
                it "should be able to add files to the internal spool", ()->
                    addTests = harness 'add'
                    out = $.add.apply $, addTests
                    $.files.each (file, key)->
                        _(addTests).contains(key).should.equal true

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
                it "should be able to generate raw files which contain external templates in inline-convert mode", ()->


    catch e
        console.warn "Error during retemplating spec: ", e
        if e.stack?
            console.warn e.stack
    
)(herald)