Model = require 'AmpersandModel'

Post = Model.extend
    props: {
        title: 'string'
        subtitle: 'string'
        tags: 'array'
        date: 'string'
        preview: 'string'
        image: 'string'
        content: 'string'
    }

module.exports = Post