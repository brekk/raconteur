"use strict"
crier = require 'raconteur-crier'
scribe = require 'raconteur-scribe'
telegraph = require './telegraph'
telepath = require './telepath'

module.exports = {
    scribe: scribe
    crier: crier.crier
    herald: crier.herald
    telegraph: telegraph
    telepath: telepath
}