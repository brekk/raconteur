_ = require 'lodash'
dust = require 'dustjs-linkedin'
promise = require 'promised-io'
Deferred = promise.Deferred

Blacksmith = ()->
    self = @
    # add a named template
    self.add = (name, template)->
        if _.isString(name) and _.isString(template)
            dust.loadSource dust.compile template, name
            return true
        return false

    # force the name tpl-XXX.dust into XXX
    unconvertName = (x)->
        if x? and _.isString x
            if x.indexOf('tpl-') is 0
                x = x.substr(4)
                if x.indexOf('.dust') isnt -1
                    x = x.split('.')[0]
        return x

    # force the name to tpl-XXX.dust when given XXX
    convertName = (x)->
        if x? and _.isString x
            if x.indexOf('tpl') is -1
                x = 'tpl-' + x + '.dust'
        return x

    # check for the existence of a key in the cache
    self.has = (x)->
        dustKeys = _.keys(dust.cache)
        if x
            name = convertName x
            return _.contains dustKeys, name
        else
            return _.map dustKeys, unconvertName

    # invoked with 3 arguments, will invoke callback with
    # rendered text or an error (#outcome)
    # invoked with 1 argument, will return a function which
    # expects a data model and a callback, which when invoked,
    # will return (#outcome)
    self.create = (name, object, cb)->
        unless name
            return false
        returnAsFunction = false
        if arguments.length is 1
            returnAsFunction = true
        name = convertName name
        unless self.has name
            return false
        if returnAsFunction
            return (data, callback)->
                if !callback? or !_.isFunction callback
                    callback = ()->
                results = dust.render name, data, callback
                return results
        if !cb? or !_.isFunction cb
            throw new TypeError "Expected callback to be function."
        return dust.render name, object, cb

    # if given both a name and an object, returns a promise of the resolved render
    # if given only a name, will return a function which returns said promise
    self.promise = (name, object)->
        name = convertName name
        render = (data)->
            d = new Deferred()
            dust.render name, data, (e, out)->
                if e
                    d.reject e
                    return
                d.resolve out
                return
            return d
        if obj? and _.isObject object
            return render()
        else
            return render

    return self

module.exports = Blacksmith