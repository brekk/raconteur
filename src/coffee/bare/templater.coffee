###
Revised version of the template generator:

Should either use gulp as a subprocess or have a separate approach for generating content without gulp (which would probably make for a nice CLI utility).

Check to see if a file exists
if yes, load it
if no, create it, then load it
###

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
    dust: ()->
        return dust.apply dust, arguments
    getSugarFiletype: ()->
        unless @sugarFiletype?
            @setSugarFiletype()
        return @sugarFiletype
    setSugarFiletype: ()->
        @sugarFiletype = '.sugar'
    # add a named template
    add: (name, template)->
        d = postpone()
        (->
            if _.isString(name) and _.isString(template)
                dust.loadSource dust.compile template, name
                d.resolve true
                return
            d.reject false
            return
        )()
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

    # if given both a name and an object, returns a promise of the resolved render
    # if given only a name, will return a function which returns said promise
    createByPromise: (name, object)->
        self = @
        render = (data)->
            d = postpone()
            dust.render name, data, (e, out)->
                if e
                    d.reject e
                    return
                d.resolve out
                return
            return d
        if object? and _.isObject object
            return render object
        else
            return render

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
        (->
            output = jade.compile sugarContent, options
            d.resolve output data
            console.warn = reference.warning
            delete reference.warning
        )()
        return d

    loadFileByPromise: (fileToLoad, addAsTemplate=null, vivify=false)->
        self = @
        if _.isArray fileToLoad
            return _(fileToLoad).map((item)->
                unless item.file?
                    return null
                if item.name?
                    if item.vivify?
                        return self.loadFileByPromise item.file, item.name, item.vivify
                    return self.loadFileByPromise item.file, item.name
                return self.loadFileByPromise item.file
            ).compact().value()

        d = postpone()
        fileReadOp = pfs.readFile fileToLoad, {
            charset: 'utf8'
        }
        bad = (err)->
            d.reject err
        good = (input)->
            output = input.toString()
            if !output? or output.length is 0
                d.reject new Error "File is empty."
                return
            if !addAsTemplate? or !_.isString addAsTemplate
                d.resolve output
                return
            addNamedTemplate = (content)->
                self.add(addAsTemplate, content).then ()->
                    if vivify?
                        if !_.isObject vivify
                            d.resolve self.createByPromise(addAsTemplate)
                            return
                        else
                            self.createByPromise(addAsTemplate, vivify).then (resolved)->
                                d.resolve resolved
                                return
                            , bad
                            return
                    d.resolve content
                    return
                , bad
            if self.getSugarFiletype() is path.extname fileToLoad
                self.convertSugarToDust(output).then addNamedTemplate, bad
            return
        fileReadOp.then good, bad
        return d
}

module.exports = Templateur