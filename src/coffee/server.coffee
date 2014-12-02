"use strict"

_ = require 'lodash'
express = require 'express'
bodyParser = require 'body-parser'
app = express()
fs = require 'fs'

templates = new (require './templates')()

postman = require './postman'

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
    
    app.get '/writing/:file', (req, res)->
        path = req.params.file
        unless path?
            throw new Error "Expected path or cash."

        options = {
            layout: false
        }
        postRenderer = templates.promise 'post'
        postman.address "#{cd}/content/"
               .box postRenderer
               .deliver path + '.md', (e, mail)->
                    if e?
                        res.send "Error sending content: ", e
                        return
                    res.send mail
        return
else
    console.log "The post template wasn't found."

port = (process.env.PORT or process.env.port) or 8888

app.listen port

console.log "Running raconteur instance on port: #{port}"