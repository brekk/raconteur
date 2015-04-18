# Raconteur
## a library for converting simple markdown to smart markup

Ever been frustrated by the need to separate the concerns of content creation (markdown) from the concerns of design (markup)?

Raconteur offers some loosely-opinionated tools to manage robust content and convert it to clean markup.

#### Tools
 1. scribe ([raconteur-scribe][]) - _a tool for dead-simple content creation in markdown and modified json._
 2. renderer ([marked][]) - _an extensible markdown parser (`marked` internally), used by the scribe._
 3. crier ([raconteur-crier][]]- _a tool for expressive and easy template creation in jade and dust._
 4. herald ([raconteur-herald][])- _a tool for creating a crier instance preloaded with templates._

[raconteur-scribe]: https://www.npmjs.com/package/raconteur-scribe "The raconteur-scribe module"
[raconteur-crier]: https://www.npmjs.com/package/raconteur-crier "The raconteur-crier module"
[raconteur-herald]: https://www.npmjs.com/package/raconteur-crier#herald "The raconteur-crier module (Herald)"
[marked]: https://www.npmjs.com/package/marked "The marked module"

#### Utilities
 1. telegraph - _a light-weight single-template implementation that binds the scribe and the crier together._
 2. telepath - _a more complex but more reusable implementation which binds the scribe and the crier together._

### scribe

## Invocation

    var scribe = require('raconteur').scribe;

The scribe is a tool for converting content (think markdown / post format) into a more reusable object format which can resolve itself to HTML, but one which also has easy-to-create metadata.

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

Here's an example of using the scribe module.

    var scribe = require('raconteur-scribe');
    var file = "./example-post.md";

We can use `scribe.readFile`, which follows the standard node-style callback (function(error, data)) and reads a markdown file into memory:

    scribe.readFile(file, function(error, data){
        if (!!error){
            console.log("error during read", error);
            return;
        }
        console.log(data.attributes);
        // prints attribute hash from file above: {title, tags, date, author}
        console.log(data.content);
        // prints markdown body as HTML
    });

We can use `scribe.readRaw`, which does the same thing as above but reads the content as a raw string:

    scribe.readRaw("{{{"title": "Hello World"}}}\n*hello* stranger.", function(error, data){
        if (error) {
            console.log(error);
            return;
        }
        console.log(data.attributes);
        // prints attribute hash from raw string above: {title}
        console.log(data.content);
        // prints markdown body as HTML
    });

Finally, we can use the promise-based version of either of those methods, `scribe.readFileAsPromise` and `scribe.readRawAsPromise` respectively, which don't expect the callback and instead return a promise:

    var happy = function(data){
        console.log(data.attributes);
        // prints attribute hash from raw string above: {title}
        console.log(data.content);
        // prints markdown body as HTML
    };
    var sad = function(error){
        console.log("error during readRaw", error.toString());
    };
    // scribe.readFileAsPromise("./example-post.md").then(happy, sad);
    // or
    scribe.readRawAsPromise("{{{"title": "Hello World"}}}\n*hello* stranger.").then(happy, sad);

##### Rendering with a custom markdown renderer

If you have a custom renderer (an instance of the `marked.renderer`), you can set it on a scribe using `scribe.setRenderer(customRendererInstance)`.

### crier

## Invocation

    var crier = require('raconteur').crier;

The crier is a tool for converting markup (either straight HTML, [jade][], or jade-and-dust together, our preferred sugar syntax) into a template (a function which can be fed data and resolves itself into a view).

Here's an example file in the preferred sugar syntax:

**example-post.sugar** - an easy to learn, expressive combination of [dust][] and [jade][]:

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

Here's an example of using the crier module. In this example we're using mock content; we recommend using the crier with the [raconteur-scribe][] module, but the modules are designed to be modular enough to be used independently:

    var crier = require('raconteur').crier;
    var fs = require('fs');
    # this example we'll do the reading ourselves, but there are other ways of adding content which we'll get to below.
    fs.readFile('./example-post.tpl', {encoding: 'utf8'}, function(e, content){
        if (!!e){
            console.log("Error during read:", e.toString());
            return
        }
        var useSugarSyntax = true;
        // this adds the template to the dust cache
        crier.add('namedTemplate', content, useSugarSyntax);
        mockContent = {
            model: {
                attributes: {
                    title: "Test",
                    author: "Brekk",
                    date: "3-30-15",
                    tags: [
                        "a",
                        "b",
                        "c"
                    ]
                },
                content: "<strong>hello</strong>"
            }
        }
        // this retrieves the named template from the dust cache, and populates it with content
        crier.create('namedTemplate', mockContent, function(e, content){
            if (!!e){
                console.log(e);
                return
            }
            console.log(content);
            // prints converted HTML
        });
    });

In addition to reading files from a source, you can also point the crier at files during runtime:

    var onLoaded = function(data){
        console.log("Things loaded.", data.attributes, data.content);
    };
    var onError = function(e){
        console.log("Error during loadFile", e.toString());
    };
    crier.loadFileAsPromise('./example-post.sugar', 'namedTemplate').then(onLoaded, onError);

Please read the tests for a better understanding of all the possible options for the crier.

### Herald

The Herald is essentially a re-wrapper for the crier. It allows you to create a custom instance of the crier with templates pre-loaded (they can either be loaded at runtime or pre-added to the output file), so the generated file already has access to the templates you want to use.

It's pretty straightforward to use, but the main configurable options are in the `herald.export` method.

**retemplater.js**

    var fs = require('fs');
    var herald = require('raconteur').herald;
    herald.add('./post.sugar');
    herald.add('./page.sugar');
    var success = function(content){
        fs.writeFile('./herald-custom.js', content, {encoding: 'utf8'}, function(){
            console.log("success");
        });
    };
    var failure = function(e){
        console.log("Error creating custom crier.", e.toString());
    };
    var settings = {
        sugar: true,
        mode: 'inline-convert',
        inflate: false
    };
    herald.export(settings).then(success, failure);

Once that retemplater file has been run, you should have a custom version of the crier which you can use instead of it:

    var crier = require('./herald-custom');
    crier.has('post.sugar'); // prints true
    crier.has('page.sugar'); // prints true
    crier.has('summary.sugar'); // prints false

[raconteur]: https://www.npmjs.com/package/raconteur "The raconteur module"
[raconteur-scribe]: https://www.npmjs.com/package/raconteur-scribe "The raconteur-scribe module"
[jade]: https://www.npmjs.com/package/jade "The jade module"
[dust]: https://www.npmjs.com/package/dustjs-linkedin "The dustjs-linkedin module"

## Utilities

### Telegraph

The Telegraph is a lightweight, single-template-only utility which joins together the functionality of both the Crier and Scribe in a single function which returns a promise.

    var telegraph = require('raconteur').telegraph;
    var postLocation = "./posts/somePost";
    fs.readFile(postLocation, {encoding: 'utf8'}, function(rawPost){
        var telegraphOperation = telegraph('post.html', '<div>{model.content|s}</div>', rawPost);
        var succeed = function(content){
            console.log("WE HAVE OUR CONTENT", CONTENT);
        };
        var fail = function(e){
            console.log("WE ARE FAILURES", e);
        };
        telegraphOperation.then(succeed, fail);
    })


### Telepath

The Telepath is a more fully featured object which joins together the functionality of the Crier and the Scribe with a convenient chainable interface.

    var telegraph = require('raconteur').telegraph;
    telepath.chain()
            .sugar() // enables sugar syntax
            .promise() // switches ready() from expecting a callback to returning a promise
            .template("post.sugar", "./templates/tpl-post.sugar")
            .post("./posts/test.md")
            .post("./posts/other-test.md")
            .post("./posts/shut-up.md")
            .ready().then(function(posts){
                console.log(posts[0]); // prints test.md x tpl-post.sugar
                console.log(posts[1]); // prints other-test.md x tpl-post.sugar
                console.log(posts[2]); // prints shut-up.md x tpl-post.sugar
            }, function(e){
                console.log("there was an error!", e);
            });

You can also give a post first followed by multiple templates:

    telepath.chain()
            .sugar()
            .post("./posts/test.md")
            .template("post.sugar", "./templates/tpl-post.sugar")
            .template("post-summary.sugar", "./templates/tpl-post-summary.sugar")
            .template("post-hero.sugar", "./templates/tpl-post-hero.sugar")
            .ready(function(e, out){
                console.log out.length // prints 3
                /*
                out[0] = test.md x post.sugar
                out[1] = test.md x post-summary.sugar
                out[2] = test.md x post-hero.sugar
                */
            });

You can also make multiple template and post declarations:

    telepath.chain()
            .sugar()
            .template("post.sugar", "./templates/tpl-post.sugar")
            .post("./posts/test.md")
            .post("./posts/other-test.md")
            .post("./posts/shut-up.md")
            .template("post-summary.sugar", "./templates/tpl-post-summary.sugar")
            .post("./posts/test.md")
            .post("./posts/other-test.md")
            .template("post-hero.sugar", "./templates/tpl-post-hero.sugar")
            .post("./posts/other-test.md")
            .post("./posts/shut-up.md")
            .ready(function(e, out){
                console.log e == null # prints true
                console.log out.length # prints 7
                /*
                    out[0] = post.sugar x test.md
                    out[1] = post.sugar x other-test.md
                    out[2] = post.sugar x shut-up.md
                    out[3] = post-summary.sugar x test.md
                    out[4] = post-summary.sugar x other-test.md
                    out[5] = post-hero.sugar x other-test.md
                    out[6] = post-hero.sugar x shut-up.md
                */
            });

In addition you can also call the `raw()` method at any time, and then the post and template methods will expect raw content instead of a filename.

    telepath.chain()
            .raw()
            .template("post.html", "<div><h1>{model.attributes.title}</h1><p>{model.content|s}</p></div>")
            .post('{{{ "title": "raw title", }}}\n# Header\n## Subheader\n*strong*\n_emphasis_')
            .ready(function(e, out){
                console.log(e == null); // prints true
                console.log(out.length); // prints 1
                console.log(out[0);] // prints the converted template populated with the raw content
            });