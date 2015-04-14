test = [
    # post >> multiple templates
    [
        {file: []}
        {sugar: []}
        {post: ['./posts/test.md']}
        {template: ['./templates/tpl-post.sugar', 'post.sugar']}
        {template: ['./templates/tpl-post-summary.sugar', 'post-summary.sugar']}
        {template: ['./templates/tpl-post-hero.sugar', 'post-hero.sugar']}
        {export: []}
    ]
    # template >> multiple posts
    [
        {file: []}
        {sugar: []}
        {template: ['./templates/tpl-post.sugar', 'post.sugar']}
        {post: ['./posts/test.md']}
        {post: ['./posts/test2.md']}
        {post: ['./posts/other-test.md']}
        {post: ['./posts/shut-up.md']}
        {export: []}
    ]
    # template >> multiple posts
    # template > single post
    # template >> multiple posts
    [
        {file: []}
        {sugar: []}
        {template: ['./templates/tpl-post.sugar', 'post.sugar']}
        {post: ['./posts/test.md']}
        {post: ['./posts/test2.md']}
        {template: ['./templates/tpl-post-summary.sugar', 'post-summary.sugar']}
        {post: ['./posts/other-test.md']}
        {template: ['./templates/tpl-post-hero.sugar', 'post-hero.sugar']}
        {post: ['./posts/test.md']}
        {post: ['./posts/test2.md']}
        {post: ['./posts/shut-up.md']}
        {export: []}
    ]
    # post >> multiple templates
    # post > single template
    # post >> multiple templates
    [
        {file: []}
        {sugar: []}
        {post: ['./posts/test.md']}
        {template: ['./templates/tpl-post.sugar', 'post.sugar']}
        {template: ['./templates/tpl-post-summary.sugar', 'post-summary.sugar']}
        {template: ['./templates/tpl-post-hero.sugar', 'post-hero.sugar']}
        {post: ['./posts/test2.md']}
        {template: ['./templates/tpl-post-hero.sugar', 'post-hero.sugar']}
        {post: ['./posts/shut-up.md']}
        {template: ['./templates/tpl-post.sugar', 'post.sugar']}
        {template: ['./templates/tpl-post-hero.sugar', 'post-hero.sugar']}
        {export: []}
    ]
]

_ = require 'lodash'

test = _(test).map((group)->
    count = Date.now()
    return _.map group, (instruction)->
        output = {timestamp: count}
        kind = _.first _.keys instruction
        output.kind = kind
        if instruction[kind]?
            output.args = instruction[kind]
            console.log "kind kind", output.args
        output.id = _.uniqueId output.kind
        count += Math.round Math.random() * 9e3
        return output
).value()

fs = require 'fs'

fs.writeFile './telepathic-chain.json', JSON.stringify(test, null, 4), {encoding: 'utf8'}, ()->
    console.log "SHUT UP SHIT PI"