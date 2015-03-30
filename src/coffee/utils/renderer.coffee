_ = require 'lodash'

marked = require 'marked'
renderer = new marked.Renderer()

module.exports = (body, r)->
    if r? and r instanceof marked.Renderer
        renderer = r
    return marked body, {
        renderer: renderer
    }