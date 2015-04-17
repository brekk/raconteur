_ = require 'lodash'
debug = require('debug') 'raconteur:telepath'
crier = require('raconteur-crier').crier
scribe = require 'raconteur-scribe'
chain = require './telepathic-chain'
promise = require 'promised-io/promise'
Deferred = promise.Deferred

module.exports = Telepath = {
    scribe: scribe
    crier: crier
}

___ = require("parkplace").scope Telepath

___.readable 'chain', ()->
    return new chain()
