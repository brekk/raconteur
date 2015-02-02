#!/usr/bin/env node

module.exports = {
    postmaster: require('./lib/postmaster'),
    renderer: require('./lib/renderer'),
    templater: require('./lib/templater'),
    bundler: require('./lib/postbundler')
};