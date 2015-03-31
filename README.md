# Raconteur
## a library for converting simple markdown to smart markup

Ever been frustrated by the need to separate the concerns of content creation (markdown) from the concerns of design (markup)?

Raconteur offers some loosely-opinionated tools to manage robust content and convert it to clean markup.

#### Tools
 1. scribe - _a tool for dead-simple content creation in markdown and modified json._
 2. renderer - _an extensible markdown parser (`marked` internally), used by the scribe._
 3. crier - _a tool for expressive and easy template creation in jade and dust._
 4. herald - _a tool for creating a crier instance preloaded with templates._

#### Utilities
 1. telegraph - _a light-weight single-template implementation that binds the scribe and the crier together._
 2. telepath - _a more complex but more reusable implementation which binds the scribe and the crier together._

## Tools

### Scribe

The Scribe is a tool for converting content (think markdown / post format) into a more reusable object format which can resolve itself to HTML, but one which also has easy-to-create metadata.

In addition to the standard markdown you probably know and love, because we're using the `marked` library internally, you can modify and extend the existing renderer. (See [below][custom-renderer] for more details.)

[custom-renderer]: #custom-renderer "Rendering with a custom markdown renderer"

#### Metadata

We're using the `json-front-matter` library under the hood, and that allows us to quickly add custom metadata to any content.

Here's an example post, using a combination of json-front-matter and markdown:

**example-post.md**:

    {{{
        "title": "The Title",
        "tags": ["a", "b", "c"],
        "date": "1-20-2015",
        "author": "brekk"
    }}}
    # Learning 
    Lorem ipsum dolor sit amet adipiscine elit.

We can easily reference any of those properties in our template later using Crier module, but more on that shortly.

Here's an example of using the Scribe module.

    scribe = require('raconteur').scribe
    file = "./example-post.md"

We can use `scribe.readFile`, which follows the standard node-style callback (function(error, data)) and reads a markdown file into memory:

    scribe.readFile file, (error, data)->
        if error
            console.log error
            return
        console.log data.attributes
        # prints attribute hash from file above: {title, tags, date, author}
        console.log data.content
        # prints markdown body as HTML

We can use `scribe.readRaw`, which does the same thing as above but reads the content as a raw string:

    scribe.readRaw "{{{"title": "Hello World"}}}\n*hello* stranger.", (error, data)->
        if error
            console.log error
            return
        console.log data.attributes
        # prints attribute hash from raw string above: {title}
        console.log data.content
        # prints markdown body as HTML

Finally, we can use the promise-based version of either of those methods, `scribe.readFileAsPromise` and `scribe.readRawAsPromise` respectively, which don't expect the callback and instead return a promise:

    happy = (data)->
        console.log data.attributes
        # prints attribute hash from raw string above: {title}
        console.log data.content
        # prints markdown body as HTML
    sad = (error)->
        console.log "error during readRaw", error.toString()
        if error.stack?
            console.log error.stack
    scribe.readFileAsPromise("./example-post.md").then happy, sad
    # or
    scribe.readRawAsPromise("{{{"title": "Hello World"}}}\n*hello* stranger.").then happy, sad

##### Rendering with a custom markdown renderer

If you have a custom renderer (an instance of the `marked.renderer`), you can set it on a Scribe using `scribe.setRenderer(customRendererInstance)`.

### Crier

The Crier is a tool for converting markup (either straight HTML, jade, or jade-and-dust together, my preferred sugar syntax) into a template (a function which can be fed data and resolves itself into a view).

Here's an example file in the preferred sugar syntax:

**example-post.sugar** - an easy to learn, expressive combination of dust and jade:

    .post
        .meta
            header
                h1|{model.attributes.title}
                h2|By {model.attributes.author}
            span.timestamp|{model.attributes.date}
        ul.tags|{#model.attributes.tags}
            li.tag|{.}
            {/model.attributes.tags}
        p.content|{model.content|s}

Here's an example of using the Crier module. In this example we're using mock content, as the Crier and Scribe modules are intended to be used together but are designed to be modular enough to be used independently. (Read more below to see more encapsulated modules / tools.):

    crier = require('raconteur').crier
    # this example we'll do the reading ourselves, but there are other ways of adding content which we'll get to below.
    fs.readFile './example-post.tpl', {encoding: 'utf8'}, (e, content)->
        if e?
            console.log "Error during read:", e.toString()
            if e.stack?
                console.log e.stack
            return
        useSugarSyntax = true
        # this adds the template to the dust cache
        crier.add 'namedTemplate', content, useSugarSyntax
        mockContent = {
            model: {
                attributes: {
                    title: "Test"
                    author: "Brekk"
                    date: "3-30-15"
                    tags: [
                        "a"
                        "b"
                        "c"
                    ]
                }
                content: "<strong>hello</strong>"
            }
        }
        # this retrieves the named template from the dust cache, and populates it with content
        crier.create 'namedTemplate', mockContent, (e, content)->
            if e?
                console.log e
                return
            console.log content
            # prints converted HTML

In addition to reading files from a source, you can also point the Crier at files during runtime:

    crier = require('raconteur').crier
    onLoaded = (data)->
        console.log "Things loaded.", data.attributes, data.content
    onError = (e)->
        console.log "Error during loadFile", e.toString()
        if e.stack?
            console.log e.stack
    crier.loadFileAsPromise('./example-post.sugar', 'namedTemplate').then onLoaded, onError

Please read the tests for a better understanding of all the possible options for the Crier.

### Herald

The Herald is essentially a re-wrapper for the Crier. It allows you to create a custom instance of the Crier with templates pre-loaded (they can either be loaded at runtime or pre-added to the output file), so the generated file already has access to the templates you want to use.

It's pretty straightforward to use, but the main configurable options are in the `herald.export` method.

**retemplater.js**

    fs = require 'fs'
    herald = require('raconteur').herald
    herald.add './post.sugar'
    herald.add './page.sugar'
    success = (content)->
        fs.writeFile './herald-custom.js', content, {encoding: 'utf8'}, ()->
            console.log "success"
    failure = (e)->
        console.log "Error creating custom crier.", e.toString()
        if e.stack?
            console.log e.stack
    settings = {
        sugar: true
        mode: 'inline-convert'
        inflate: false
    }
    herald.export(settings).then success, failure

Once that retemplater file has been run, you should have a custom version of the Crier which you can use instead of it:

    crier = require('./herald-custom')
    crier.has 'post.sugar' # prints true
    crier.has 'page.sugar' # prints true
    crier.has 'summary.sugar' # prints false

## Utilities

### Telegraph

The Telegraph is a lightweight single-template-only utility which joins together the functionality of both the Crier and Scribe in a single function.
