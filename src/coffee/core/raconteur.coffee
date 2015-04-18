"use strict"
crier = require 'raconteur-crier'
scribe = require 'raconteur-scribe'
telegraph = require './telegraph'
telepath = require './telepath'

module.exports = {
    markdown: scribe
    markup: crier
    telegraph: telegraph
    telepath: telepath
}