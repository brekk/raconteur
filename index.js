#!/usr/bin/env node

module.exports = {
    postman: require('./build/postmaster'),
    renderer: require('./build/renderer'),
    templater: require('./build/templater'),
    bundler: require('./build/postbundler')
};
