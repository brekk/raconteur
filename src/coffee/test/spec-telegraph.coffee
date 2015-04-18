assert = require 'assert'
should = require 'should'
_ = require 'lodash'
cwd = process.cwd()
telegraph = require cwd + '/lib/telegraph'

(($)->
    "use strict"
    try
        testPost = '''{{{
            "title":"Very Important Test Work",
            "subtitle":"It's not really that important.",
            "slug":"vip-test",
            "tags": ["zip", "zop", "test", "tester"],
            "date":"10-27-2014",
            "preview":"This is a summary of a very boring (but probably also important) test work. Do we support hatemail entities?",
            "image":""
        }}}

        # Handgloves (h1)
        Twee bespoke dreamcatcher, +1 hoodie non fashion axe [narwhal][] chia synth qui Blue Bottle cray flannel biodiesel. Chillwave photo booth dolore tousled laboris, Banksy Pitchfork Wes Anderson ea blog banh mi delectus mollit *Williamsburg* actually. Bicycle rights scenester *PBR Blue Bottle wolf*. Roof party irure *Williamsburg* hashtag. Slow-carb photo booth consequat aliquip, master cleanse pork belly pariatur Intelligentsia. Delectus mlkshk you probably haven't heard of them ethical, Vice nihil Neutra do *Williamsburg* brunch gluten-free occupy anim selvage. Tempor trust fund accusamus sed umami mlkshk, irure chambray tousled gentrify et try-hard aesthetic nostrud.

        *  [Skateboard art party](http://yercom.mom "This is a bad link.") semiotics, tote bag deep v High Life tofu Intelligentsia deserunt kitsch Banksy synth.
        *  Pitchfork art party do irony ad, est Shoreditch.
           -  Carles meditation forage, leggings authentic sapiente delectus heirloom dolore.
           -  Wes Anderson typewriter consectetur, dreamcatcher 3 wolf moon retro assumenda drinking vinegar odio.

        [narwhal]: http://jibbblejobble.bobble "This is another bad link."
        '''
        call = (templateContent, postContent, opts, assertion, done)->
            makeOp = $('post', templateContent, postContent, opts)
            good = (content)->
                content.should.be.ok
                (typeof content).should.equal 'string'
                assertion content
                done()
            bad = (e)->
                e?.should.not.be.ok
            makeOp.then good, bad
        describe "Telegraph", ()->
            it "should convert a template and content into a rendered html string", (done)->
                postContent = testPost
                templateContent = "<div><h1>{model.title}</h1><p>{model.content|s}</p></div>"
                call templateContent, postContent, {}, (content)->
                    content.should.be.ok
                , done
            it "should allow for sugar conversion", (done)->
                postContent = testPost
                templateContent = "article.post\n\t.content\n\t\t.drawn(role=\"drawn-content\")\n\t\t\timg(src=\"{model.attributes.image}\")\n\t\t.written\n\t\t\theader\n\t\t\t\th1.title(role=\"title\")|{model.attributes.title}\n\t\t\t\th2.subtitle(role=\"subtitle\")|{model.attributes.subtitle}\n\t\t\t\tul.tags|{#model.attributes.tags}\n\t\t\t\t\tli.tag|{.}\n\t\t\t\t\t{/model.attributes.tags}\n\t\t\t.data(role=\"written-content\")|{model.content|s}\n\t\tfooter\n\t\t\t.meta(data-timestamp=\"0\")\n\t\t\t\t.time(role=\"timestamp\")|{model.attributes.timestamp}\n\t\t\t\t.category(role=\"category\")|{model.attributes.category}"
                call templateContent, postContent, {
                    sugar: true
                }, (content)->
                    content.should.be.ok
                , done

    catch e
        console.warn "Error during retemplating spec: ", e
        if e.stack?
            console.warn e.stack
    
)(telegraph)