# Raconteur
## a library for converting simple markdown to smart markup

Ever been frustrated by the need to separate the concerns of content creation (markdown) from the concerns of design (markup)?

Raconteur offers some loosely-opinionated tools to manage robust content and convert it to clean markup.

 1. postmaster - _a tool for converting markdown and front-matter to a json-encoded html format._
 2. renderer - _a customized and extensible markdown parser (using `marked` internally), used by the postmaster._
 3. templater - _a wrapper around the dustjs-linkedin module which allows for "sugar" syntax._
 4. bundler - _a simple implementation that binds the postmaster and the templater together._

### Postmaster

Write content using simple markdown and a triple-curly-braced JSON header (more below) and easily convert it to HTML encoded within JSON.

**post.md** - a combination of json-front-matter and markdown:

    {{{
        "title": "The Title",
        "tags": ["a", "b", "c"],
        "date": "1-20-2015"
    }}}
    # Learning 
    Lorem ipsum dolor sit amet snibbie dibby.

**post.sugar** - a combination of dust and jade:

    .post
        h1|{model.title}
        ul.tags|{#model.attributes.tags}
            li.tag|{.}
        {/model.attributes.tags}
        p|{model.content|s}
