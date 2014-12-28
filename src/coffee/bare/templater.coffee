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


Templateur = {
    sugarFiletype: '.sugar'
    ###*
    * Return the sugarFiletype
    * @method getSugarFiletype
    * @return String - sugarFileType
    ###
    getSugarFiletype: ()->
        return @sugarFiletype

    ###*
    * Set the filetype to use, for custom filetypes
    * @method setSugarFiletype
    * @param {String} type - the file extension to use for sugar types. Defaults to .sugar
    * @return String - sugarFileType
    ###
    setSugarFiletype: (type)->
        unless type?
            type = @sugarFiletype
        if type? and _.isString type
            if type[0] isnt '.'
                type = '.' + type
            @sugarFiletype = type
        return @sugarFiletype

    ###*
    * add a named template
    * @method add
    * @param {String} name - the name of the template to store
    * @param {String} template - the dust text to template
    * @return Promise p
    ###
    add: (name, templateString, sugar=false)->
        d = postpone()
        addToDust = (template)->
            if !_.isString(name) or !_.isString(template)
                d.reject new TypeError "Expected both name and template to be strings."
                return
            dust.loadSource dust.compile template, name
            d.resolve true
            return
        if sugar? and sugar
            @convertSugarToDust(templateString).then addToDust, (e)->
                d.reject e
                return
            return d
        addToDust templateString
        return d

    # check for the existence of a key in the cache
    has: (name)->
        self = @
        dustKeys = _.keys(dust.cache)
        if name
            return _.contains dustKeys, name

    # invoked with 3 arguments, will invoke callback with
    # rendered text or an error (#outcome)
    # invoked with 1 argument, will return a function which
    # expects a data model and a callback, which when invoked,
    # will return (#outcome)
    create: (name, object, cb)->
        self = @
        unless name?
            return false
        returnAsFunction = false
        if arguments.length is 1
            returnAsFunction = true
        unless self.has name
            return false
        unless returnAsFunction
            if !cb? or !_.isFunction cb
                throw new TypeError "Expected callback to be function."
        else
            # returnAsFunction
            return (data, callback)->
                if !callback? or !_.isFunction callback
                    callback = ()->
                results = dust.render name, data, callback
                return results
        return dust.render name, object, cb

    ###*
    * 
    * @method createByPromise
    * @param {String} name - name of cached template (added via self.add)
    * @param {Object} object - the 
    ###
    createByPromise: (name, object)->
        self = @
        # our dust render wrapper
        render = (data)->
            d = postpone()
            dust.render name, data, (e, out)->
                if e
                    d.reject e
                    return
                d.resolve out
                return
            return d
        # if given both a name and an object, returns a promise of the resolved render
        if object? and _.isObject object
            return render object
        # if given only a name, will return a function which returns said promise
        return render

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
    convertSugarToDust: (sugarContent, data, options)->
        d = postpone()
        self = @
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
            d.resolve output data
            # restore the console.warn function
            console.warn = reference.warning
            # and delete our reference to it
            delete reference.warning
            return
        )()
        # return the promise
        return d

    ###*
    * Read a file or files and add them to the dust.cache via 
    * @method loadFileByPromise
    * @param {String|Array} fileToLoad - String or Array of objects which have the format: {file, name, vivify}
    * @param {null|String} addAsTemplate - null or String
    * @param {Boolean|Object} vivify - boolean or object
    ###
    loadFileByPromise: (fileToLoad, addAsTemplate=null, vivify=false)->
        self = @
        if _.isArray fileToLoad
            # because our main function always returns a promise
            # we have to call promise.all to make sure that
            return promise.all _(fileToLoad).map((item)->
                # depending on what we've been given
                unless item.file?
                    # this will get compacted
                    return null

                args = [item.file]
                # add to the arguments
                if item.name?
                    args.push item.name
                    # if we have them
                    if item.vivify?
                        args.push item.vivify
                # call the arguments by function.apply
                # the returned result will always be a promise
                return self.loadFileByPromise.apply self, args
            ).compact().value()

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
            # the second parameter (addAsTemplate), enables the more complicated
            # output, so exit here if we can
            if !addAsTemplate? or !_.isString addAsTemplate
                d.resolve output
                return
            # our callback
            addNamedTemplate = (content)->
                # register the template with the content
                self.add(addAsTemplate, content).then ()->
                    # if vivify is either true or an object
                    if vivify? and vivify
                        if !_.isObject vivify
                            # give back a promise-returning function
                            d.resolve self.createByPromise addAsTemplate
                            return
                        else
                            # give back a fully transformed template
                            self.createByPromise(addAsTemplate, vivify).then (resolved)->
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
            if self.getSugarFiletype() is path.extname fileToLoad
                self.convertSugarToDust(output).then addNamedTemplate, bad
            else
                # otherwise, call our callback with the output
                addNamedTemplate output
            return
        # read the file, then proceed with either callback
        fileReadOp.then good, bad
        # give back the promise
        return d
}

module.exports = Templateur