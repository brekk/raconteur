"use strict"

_ = require 'lodash'
express = require 'express'
bodyParser = require 'body-parser'
app = express()
fs = require 'fs'

# wrap slug with forced lowercase behavior
slug = _.wrap (require 'slug'), (fn)->
    args = _(_.rest(arguments)).map((x)->
        if _.isString x
            return x.toLowerCase()
        return x
    ).value()
    return fn.apply null, args

marked = require 'marked'
renderer = new marked.Renderer()

frontmatter = require 'json-front-matter'
templates = new (require './templates')()

process.on 'uncaughtException', (finalError)->
    if finalError?
        console.warn "Uncaught Exception! ", finalError
        if finalError.stack?
            console.warn finalError.stack
        throw finalError

cd = process.cwd()

# config = require "#{cd}/config/default.json"
config = {
    directories: {
        public: './build/public'
    }
    debug: true
}

app.set 'env', config.env or process.env
app.set 'views', config.directories.views
# we want to be able to use .powder
app.set 'view engine', 'jade'

app.use bodyParser.urlencoded {extended: false}
app.use bodyParser.json()

# serve our public directory
app.use express.static config.directories.public

show404 = (req, res, err)->
    if err
        console.log req.method, req.url, err
    res.render '404', {url: req.url}, (err, html)->
        if err
            res.send 500, err
            return
        res.send html
        return

if templates.has 'post'

    app.get '/', (req, res)->
        options = {
            layout: false
        }
        res.render 'index', options, (err, html)->
            if err
                if !config.debug
                    show404 req, res, err
                else
                    console.log "Error during page render.", err
                    throw err
                return
            res.send html
            return

    console.log "Posts loaded!"
    postRenderer = templates.promise 'post'
    app.get '/writing/:file', (req, res)->
        path = req.params.file
        unless path?
            throw new Error "Expected path or cash."

        options = {
            layout: false
        }
        # console.log ">>> rendro stupendo\n\n", renderer
        properties = [
            "code"
            "blockquote"
            "html"
            # "heading"
            "hr"
            "list"
            "listitem"
            "paragraph"
            "table"
            "tablerow"
            "tablecell"
            "strong"
            "em"
            "codespan"
            "br"
            "del"
            "link"
            "image"
        ]
        magicList = {}
        # how many levels should get id attributes slugged?
        sluggable = [ 1, 2 ]

        # magic heading
        renderer.heading = (text, level)->
            header = 'h'+level
            ident = ""
            if _.contains sluggable, level
                headerSlug = slug text
                ident = ' id="'+headerSlug+'"'
            # do regular thing
            unless level is 6
                # standard interpolation
                return "<#{header}#{ident}>#{text}</#{header}>"
            # magic header time!
            # store a reference to it, probably?
            # console.log "this is a magic header!", text
            first = text.substr 0, 1
            rest = text.substr 1
            parts = rest.split '-'
            # console.log ">>>>> FIRSTO", first
            if '$' is first
                noop = (x)->
                    return x
                modifier = noop
                inner = true

                # magic properties
                TABLE_OF_CONTENTS = 'toc'

                # transformations

                # simple slug menu links
                slugWrap = (content)->
                    slugged = slug content
                    return "<a href=\"##{slugged}\">#{content}</a>"

                if _.contains parts, TABLE_OF_CONTENTS
                    inner = true
                    modifier = slugWrap

                preload = ()->
                    unless magicList[rest]?
                        magicList[rest] = {
                            list: []
                            inner: inner
                        }

                renderer.list = (content, ordered)->
                    preload()
                    if magicList[rest]?
                        unless magicList[rest].ordered?
                            magicList[rest].ordered = ordered
                    return ""

                renderer.listitem = (content)->
                    preload()
                    if magicList[rest]?
                        if modifier?
                            magicList[rest].modifier = modifier
                        if magicList[rest]?.list?
                            magicList[rest].list.push content
                    return ""
                    # else
                    #     return "<li>#{content}</li>"
                    # return content
            else if '^' is first
                if magicList[rest]?
                    if renderer.listitem?
                        delete renderer.listitem
                    if renderer.list?
                        delete renderer.list
                return _(magicList).map((reference, key)->
                    list = modifier = inner =  null
                    if reference?.list?
                        list = reference.list
                    if reference?.modifier?
                        modifier = reference.modifier
                    if reference?.inner?
                        inner = reference.inner
                    if reference?.ordered?
                        ordered = reference.ordered
                    if list?
                        item = if ordered then 'ol' else 'ul'
                        wrapHead = "<#{item}>"
                        wrapTail = "</#{item}>"
                        inner = _(list).map((item)->
                            data = null
                            if modifier?
                                if inner?
                                    if inner
                                        item = modifier item
                                        data = "<li>#{item}</li>"
                                    else # outer
                                        data = "<li>#{item}</li>"
                                        data = modifier data
                            if data?
                                return data
                            return ""
                        ).value().join('')
                        return wrapHead + inner + wrapTail

                ).value()
            return ""




        frontmatter.parseFile "#{cd}/content/" + path + '.md', (err, frontdata)->
            if err
                console.log "Error reading file:", err
                throw err
            unless frontdata?
                throw new Error "Expected data from FrontMatter."
            {body, attributes} = frontdata
            # console.log "THESE ARE THE ATTRIBUTES", attributes
            output = marked body, {
                renderer: renderer
            }
            if output?
                post = {
                    model: {
                        attributes: attributes
                        content: output
                        raw: body
                    }
                }
                renderPromise = postRenderer post
                renderPromise.then (converted)->
                    res.send converted
                , (e)->
                    console.log "error somewhurr", e
                    res.send e
                return    
            res.send "It didn't work! IDIOT!"
        return
else
    console.log "The post template wasn't found."

port = (process.env.PORT or process.env.port) or 8888

app.listen port

console.log "Running raconteur instance on port: #{port}"