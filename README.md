# Raconteur
## a library for converting simple markdown to smart markup

Ever been frustrated by the need to separate the concerns of content creation (markdown) from the concerns of design (markup)?

Raconteur offers some loosely-opinionated tools to manage robust content and convert it to clean markup.

### Tools
 1. scribe / postmaster - _a tool for converting markdown and front-matter to a json-encoded html format._
 2. renderer - _an extensible markdown parser (`marked` internally), used by the scribe._
 3. crier / templater - _a wrapper around the dustjs-linkedin module which allows for "sugar" syntax._
 4. herald / retemplater - _a way of automagically loading templates at or before runtime and re-writing the crier._

### Utilities
 1. telegraph - _a light-weight single-template implementation that binds the scribe and the crier together._
 2. telepath - _a more complex but more reusable implementation which binds the scribe and the crier together._

### Scribe

Write content using simple markdown and a triple-curly-braced JSON header (more below) and easily convert it to HTML encoded within JSON.

**post.md** - a combination of json-front-matter and markdown:

    {{{
        "title": "The Title",
        "tags": ["a", "b", "c"],
        "date": "1-20-2015"
    }}}
    # Learning 
    Lorem ipsum dolor sit amet snibbie dibby.

**scribe-demo.coffee**




**post.sugar** - a combination of dust and jade:

    .post
        h1|{model.title}
        ul.tags|{#model.attributes.tags}
            li.tag|{.}
        {/model.attributes.tags}
        p|{model.content|s}
