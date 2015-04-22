"use strict"

_ = require 'lodash'
debug = require('debug') 'raconteur:telepath'
chain = require './telepathic-chain'

module.exports = Telepath = {}

___ = require("parkplace").scope Telepath

___.readable 'chain', ()->
    debug 'creating new chain'
    return new chain()