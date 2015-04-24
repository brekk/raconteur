assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
telepath = require cwd + '/lib/telepath'
path = require 'path'
chalk = require 'chalk'

(($)->
    "use strict"
    try
        locFix = (path)->
            return cwd + "/test/fixtures" + path
        describe "Telepath", ()->
            describe ".chain()", ()->
                describe "a basic chain", ()->
                    it "should have all of the methods available to the chain object", ()->
                        $.chain().should.have.properties 'sugar', 'raw', 'file', 'lookup', 'post', 'template', 'ready'
                    it "should generate chains via a factory function", ()->
                        chain1 = $.chain()
                        $.chain().should.not.equal chain1
                describe ".sugar()", ()->
                    it "should set the sugar state to true", ()->
                        chain = $.chain()
                        chain._mode.sugar.should.not.be.ok
                        chain.sugar().should.equal chain
                        chain._mode.sugar.should.be.ok
                describe ".promise()", ()->
                    it "should set the promise state to true", ()->
                        chain = $.chain()
                        chain._mode.promise.should.not.be.ok
                        chain.promise().should.equal chain
                        chain._mode.promise.should.be.ok
                describe ".raw()", ()->
                    it "should set the raw state to true", ()->
                        chain = $.chain()
                        chain._mode.raw.should.not.be.ok
                        chain._mode.file.should.be.ok
                        chain.raw().should.equal chain
                        chain._mode.raw.should.be.ok
                        chain._mode.file.should.not.be.ok
                        chain.fileMode.should.not.be.ok
                describe ".file()", ()->
                    it "should set the file state to true", ()->
                        chain = $.chain()
                        chain._mode.raw.should.not.be.ok
                        chain._mode.file.should.be.ok
                        chain.file().should.equal chain
                        chain._mode.raw.should.not.be.ok
                        chain._mode.file.should.be.ok
                        chain.fileMode.should.be.ok
                describe ".file().raw()", ()->
                    it "should set the raw state to true", ()->
                        chain = $.chain()
                        chain._mode.raw.should.not.be.ok
                        chain._mode.file.should.be.ok
                        chain.file().raw().should.equal chain
                        chain._mode.raw.should.be.ok
                        chain._mode.file.should.not.be.ok
                        chain.fileMode.should.not.be.ok
                describe ".ready()", ()->
                    it "should throw an Error without any post or template invocations", (done)->
                        chain = $.chain()
                        chain.ready (e)->
                            e.should.be.ok
                            arguments.length.should.equal 1
                            done()
                    it "should should convert yaml successfully", (done)->
                        finish = _.after 2, done

                        $.chain()
                         .sugar()
                         .promise()
                         .json()
                         .template("post.sugar", locFix "/templates/tpl-post.sugar")
                         .post(locFix "/posts/yaml-test.md", {yaml: true})
                         .ready().then (out)->
                                out.should.be.ok
                                out.length.should.equal 1
                                finish()

                        $.chain()
                         .sugar()
                         .promise()
                         .yaml()
                         .template("post.sugar", locFix "/templates/tpl-post.sugar")
                         .post(locFix "/posts/yaml-test.md")
                         .ready().then (out)->
                                out.should.be.ok
                                out.length.should.equal 1
                                finish()

                    it "should return the cross-product of all requested templates and posts", (done)->
                        finish = _.after 3, done
                        $.chain()
                         .sugar()
                         .post(locFix "/posts/test.md")
                         .template("post.sugar", locFix "/templates/tpl-post.sugar")
                         .template("post-summary.sugar", locFix "/templates/tpl-post-summary.sugar")
                         .template("post-hero.sugar", locFix "/templates/tpl-post-hero.sugar")
                         .ready (e, out)->
                                e?.should.equal false
                                out.should.be.ok
                                out.length.should.equal 3
                                finish()

                        $.chain()
                         .sugar()
                         .template("post.sugar", locFix "/templates/tpl-post.sugar")
                         .post(locFix "/posts/test.md")
                         .post(locFix "/posts/other-test.md")
                         .post(locFix "/posts/shut-up.md")
                         .template("post-summary.sugar", locFix "/templates/tpl-post-summary.sugar")
                         .post(locFix "/posts/test.md")
                         .post(locFix "/posts/other-test.md")
                         .post(locFix "/posts/shut-up.md")
                         .ready (e, out)->
                                e?.should.equal false
                                out.should.be.ok
                                out.length.should.equal 6
                                finish()

                        good = (out)->
                            out.should.be.ok
                            out.length.should.equal 7
                            finish()
                        bad = (e)->
                            console.log e, 'error'
                        $.chain()
                         .sugar()
                         .promise()
                         .template("post.sugar", locFix "/templates/tpl-post.sugar")
                         .post(locFix "/posts/test.md")
                         .post(locFix "/posts/other-test.md")
                         .post(locFix "/posts/shut-up.md")
                         .template("post-summary.sugar", locFix "/templates/tpl-post-summary.sugar")
                         .post(locFix "/posts/test.md")
                         .post(locFix "/posts/other-test.md")
                         .template("post-hero.sugar", locFix "/templates/tpl-post-hero.sugar")
                         .post(locFix "/posts/other-test.md")
                         .post(locFix "/posts/shut-up.md")
                         .ready().then good, bad

    catch e
        console.log "Error during Spec-telepath testing", e
        if e.stack?
            console.log e.stack
)(telepath)