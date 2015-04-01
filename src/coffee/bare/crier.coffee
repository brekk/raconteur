'use strict'

_ = require 'lodash'
dust = require 'dustjs-linkedin'
jade = require 'jade'
promise = require 'promised-io/promise'
pfs = require 'promised-io/fs'
path = require 'path'
Deferred = promise.Deferred

postpone = ()->
    d = new Deferred()
    d.yay = _.once d.resolve
    d.nay = _.once d.reject
    return d

debug = require('debug') 'raconteur:templater'

module.exports = Crier = {}

___ = require('parkplace').scope Crier

SUGAR_FILE_TYPE = '.sugar'

___.readable 'sugarFileType', {
    get: ()->
        return SUGAR_FILE_TYPE
    set: (type)->
        unless type?
            type = SUGAR_FILE_TYPE
            return SUGAR_FILE_TYPE
        if type? and _.isString type
            if type[0] isnt '.'
                type = '.' + type
            debug ".set sugarFileType: Setting sugar filetype: %s", type
            SUGAR_FILE_TYPE = type
        return SUGAR_FILE_TYPE
}, true

###*
* add a named template
* @method add
* @param {String} name - the name of the template to store
* @param {String} template - the dust text to template
* @param {Boolean} sugar=false - convert from sugar first?
* @param {Function} callback - a callback
###
___.readable 'add', (name, templateString, sugar=false, callback)->
    addToDust = (template)->
        if !_.isString(name) or !_.isString(template)
            callback new TypeError "Expected both name and template to be strings."
            return
        debug ".add: adding named template (%s) to dust"
        dust.loadSource dust.compile template, name
        callback null, true
        return
    if sugar? and sugar
        debug "converting from sugar first"
        @convertSugarToDust(templateString).then addToDust, (e)->
            debug ".add: error during sugarToDust conversion: %s", e.toString()
            callback e
            return
        return
    addToDust templateString

###*
* add a named template
* @method add
* @param {String} name - the name of the template to store
* @param {String} template - the dust text to template
* @param {Boolean} sugar=false - convert from sugar first?
* @return {Promise} addPromise
###
___.readable 'addAsPromise', (name, templateString, sugar=false)->
    d = postpone()
    @add name, templateString, sugar, (error, response)->
        if error?
            d.reject error
            return
        d.resolve response
        return
    return d

# check for the existence of a key in the cache
___.readable 'has', (name)->
    dustKeys = _.keys(dust.cache)
    if name
        return _.contains dustKeys, name
    return false

___.readable 'remove', (name, cb)->
    if _.isString name
        if dust.cache[name]?
            delete dust.cache[name]
            debug ".remove: removed named template: %s", name
            cb null, true
        else
            debug ".remove: no named template: %s", name
            cb null, true
        return
    cb new TypeError "Expected name to be a string."
    

___.readable 'removeAsPromise', (name)->
    d = new Deferred()
    @remove name, (error, success)->
        if error?
            d.reject error
            return
        d.resolve success
        return 
    return d

###*
* Creates a template or a function which renders a template
* When invoked with 3 arguments, it will invoke the callback with
* rendered text (#outcome) or an error
* invoked with 1 argument, will return a function which
* expects a data model and a callback, which when invoked,
* will return (#outcome) or an error
* @method create
* @param {String} name - name of cached template (added via self.add)
* @param {Object} [object] - the optional data object
* @param {Function} [cb] - the optional callback
###
___.readable 'create', (name, object, cb)->
    self = @
    unless name?
        cb new Error "Expected name to be given."
        return
    unless self.has name
        debug ".create: named template (%s) does not exist", name
        cb new Error "Named template doesn't (%s) exist", name
        return
    templateMaker = @makeTemplate name
    if (arguments.length is 1)
        return templateMaker
    return templateMaker object, cb

###*
* Make a template from a named template
* @method makeTemplate
* @param {String} name - the name of the cached template (added via self.add)
* @return (Function) template - a generated template
###
___.guarded 'makeTemplate', (name)->
    unless @has name
        debug ".create: named template (%s) does not exist", name
        return false
    return (data, callback)->
        debug ".create(->): render function invoked"
        if !callback? or !_.isFunction callback
            throw new TypeError "Expected a callback."
            # callback = ()->
        result = dust.render name, data, callback
        debug ".create(->): successfully rendered"
        return result

###*
* The same thing as create, but utilizing the promise pattern
* @method createAsPromise
* @param {String} name - name of cached template (added via self.add)
* @param {Object} [object] - the optional data object 
###
___.readable 'createAsPromise', (name, object)->
    render = @makeTemplate name
    promisable = (obj)->
        d = postpone()
        if obj? and _.isObject obj
            debug "createAsPromise: rendering and returning promise"
            render obj, (error, content)->
                if error?
                    d.reject error
                    return
                d.resolve content
                return
            return d
    if arguments.length is 1
        return promisable
    return promisable object

###*
* Convert a sugar file
* our sugar files are essentially jade files with some dust markup that Jade ignores
* As right now jade happens to throw warnings that aren't removable, so there's a
* temporary hack we use to remove console.warn
* @method convertSugarToDust
* @param {String} sugarContent - the content to convert from Jade to Dust
* @param {Object} data - the data to inject into the Jade content (currently unused)
* @param {Object} options - the options to give to jade (currently unused)
###
___.readable 'convertSugarToDust', (sugarContent, data, options)->
    try
        d = postpone()
        reference = {
            warning: false
        }
        unless data?
            data = {}
        unless options?
            options = {}
        # jade has no silent option, so this is a temporary hack
        if console.warn?
            reference.warning = console.warn
            console.warn = (()->)
        # immediate function
        (->
            output = jade.compile sugarContent, options
            # resolve our compiled content
            debug "convertSugarToDust: converting..."
            d.resolve output data
            # restore the console.warn function
            console.warn = reference.warning
            # and delete our reference to it
            delete reference.warning
            return
        )()
        # return the promise
        return d
    catch e
        debug 'convertSugarToDust: error converting jade to dust: %s', e.toString()
        d.reject e
        if e.stack?
            console.log e.stack

###*
* Read a file or files and add them to the dust.cache via 
* @method loadFileAsPromise
* @param {String|Array} fileToLoad - String or Array of objects which have the format: {file, name, inflate}
* @param {null|String} templateName - null or String
* @param {Boolean|Object} inflate - boolean or object
###
___.readable 'loadFileAsPromise', (fileToLoad, templateName=null, inflate=false, useSugar=false)->
    self = @
    # make yo'self a deferred
    d = postpone()
    # pull out a promise
    fileReadOp = pfs.readFile fileToLoad, {
        charset: 'utf8'
    }
    # right now we reuse this bad callback for all the parts of our possible logic chain
    bad = (err)->
        d.reject err
    # our first of many possible callbacks
    good = (input)->
        # pull it out from the buffer
        output = input.toString()
        # make sure to throw an error if given an empty file
        if !output? or output.length is 0
            d.reject new Error "File is empty."
            return
        # the second parameter (templateName), enables the more complicated
        # output, so exit here if we can
        if !templateName? or !_.isString templateName
            bad new TypeError "Expected templateName to be a string."
            return
        # our callback
        addNamedTemplate = (content)->
            # register the template with the content
            self.addAsPromise(templateName, content, useSugar).then ()->
                # if inflate is either true or an object
                if inflate? and inflate
                    if !_.isObject inflate
                        # give back a promise-returning function
                        d.resolve self.createAsPromise templateName
                        return
                    else
                        # give back a fully transformed template
                        self.createAsPromise(templateName, inflate).then (resolved)->
                            # ressy res
                            d.resolve resolved
                            return
                        , bad
                        return
                # otherwise, just resolve as true
                d.resolve true
                return
            , bad
        # if it's a sugarfile, do a preconversion for it (jade > dust)
        if useSugar or (self.sugarFileType is path.extname fileToLoad)
            self.convertSugarToDust(output).then addNamedTemplate, bad
        else
            # otherwise, call our callback with the output
            addNamedTemplate output
        return
    # read the file, then proceed with either callback
    fileReadOp.then good, bad
    # give back the promise
    return d