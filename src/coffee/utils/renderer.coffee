_ = require 'lodash'

marked = require 'marked'
renderer = new marked.Renderer()

# wrap slug with forced lowercase behavior
slug = _.wrap (require 'slug'), (fn)->
    args = _(_.rest(arguments)).map((x)->
        if _.isString x
            return x.toLowerCase()
        return x
    ).value()
    return fn.apply null, args

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

module.exports = (body, r)->
    if r? and r instanceof marked.Renderer
        renderer = r
    return marked body, {
        renderer: renderer
    }