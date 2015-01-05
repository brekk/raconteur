#!/usr/bin/env node

module.exports = {
    postman: require('./build/postman'),
    renderer: require('./build/marked-renderer'),
    post: require('./build/post-model'),
    blacksmith: require('./build/blacksmith')
};