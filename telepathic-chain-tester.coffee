_ = require 'lodash'
echo = _.bind console.log, console
commandSet = require './telepathic-chain.json'
$ = new (require './lib/telepathic-chain')()

console.log $, "<<< whodat"

_.map commandSet, (set)->
    return _.reduce set, (last, test, idx)->
        fn = null
        if test?.kind? and last?[test.kind]?
            fn = last[test.kind]
        unless fn?
            throw new Error "Expected test.kind to be a method."
        if test.args?
            if test.kind is 'export'
                test.args.push (error, success)->
                    console.log ">>>>", arguments
            console.log "...", test.kind, ": ", test.args
            outcome = fn.apply $, test.args
            unless last?
                last = outcome
            return last
    , $