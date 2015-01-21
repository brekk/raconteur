#!/usr/bin/env node

module.exports = {
    postmaster: require('./build/postmaster'),
    renderer: require('./build/renderer'),
    templater: require('./build/templater'),
    bundler: require('./build/postbundler')
};