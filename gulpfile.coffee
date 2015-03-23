# require some stuff

_ = require 'lodash'

gulp = require 'gulp'
download = require 'gulp-download'

utility = require 'gulp-util'

watch = require 'gulp-watch'
plumber = require 'gulp-plumber'

chalk = require 'chalk'

cpr = require 'cp-r'
mkdirp = require 'mkdirp'
del = require 'del'

coffee = require 'gulp-coffee'

uglify = require 'gulp-uglify'

concat = require 'gulp-concat'
flatten = require 'gulp-flatten'
header = require 'gulp-header'
footer = require 'gulp-footer'
rename = require 'gulp-rename'
streamqueue = require 'streamqueue'

browserify = require 'browserify'
source = require 'vinyl-source-stream'
through = require 'through2'

stylus = require 'gulp-stylus'
prefix = require 'gulp-autoprefixer'
minicss = require 'gulp-minify-css'

yuidoc = require 'gulp-yuidoc'
mocha = require 'gulp-mocha'

dust = require 'gulp-dust'
jade = require 'gulp-jade'

newer = require 'gulp-newer'
notify = require 'gulp-notify'

fs = require 'fs'
os = require 'os'

path = require 'path'

# listen for exceptions

process.on 'uncaughtException', (finalError)->
    if finalError?
        console.log "Error during gulping:", finalError

structure = require './raconfig.json'

config = {}
if fs.existsSync './config/default.json'
    config = require './config/default.json'


# Simple move tasks

gulp.task 'move', [
    # 'move:markdown'
    'move:assets'
] 

# gulp.task 'move:markdown', ()->
#     gulp.src structure.build.paths.content.markdown
#         .pipe gulp.dest './build/posts'

gulp.task 'move:assets', ()->
    gulp.src structure.build.paths.content.assets
        .pipe gulp.dest './lib/public/images'

gulp.task 'convert', [
    'convert:coffee'
    'convert:stylus'
    'convert:dust'
]

gulp.task 'convert:coffee', [
    'convert:coffee:wrapped'
    'convert:coffee:bare'
]

pipeNotification = (stream, settings)->
    # we could check against other stuff later
    invalidSystem = (os.arch() is 'arm')
    unless invalidSystem
        stream.pipe notify settings
    return stream

# most coffee files should be wrapped for safety
gulp.task 'convert:coffee:wrapped', ()->
    files = []
    afterLast = _.once ()->
        if files? and files.length > 0
            console.log '[ ' + files.join(', ') + " ] #{files.length} files total."
    notification = {
        message: (file)->
            files.push file.relative
            string = "Converted coffee file: <%= file.relative %> "
            afterLast()
            return string
        onLast: true
    }
    destination = './lib'
    source = structure.build.paths.source.coffee
    source.push "!" + structure.build.paths.source.barecoffee
    stream = gulp.src source
                 .pipe coffee()
                 .pipe flatten()
    pipeNotification stream, notification
    stream.pipe gulp.dest destination

gulp.task 'test:copy-fixtures', (done)->
    source = structure.build.paths.source.fixtures
    dest = process.cwd() + '/test/fixtures'
    finish = _.once ()->
        console.log "copied files from #{source} to #{dest}"
        done()
    cpr(source, dest).read finish
    return

gulp.task 'test:coffee', [
    'test:copy-fixtures'
],()->
    destination = './test'
    source = structure.build.paths.source.tests
    gulp.src source
        .pipe coffee()
        .pipe gulp.dest destination

# but some other coffee files shouldn't be wrapped, for extra magic
###
Currently this list includes:
*  Templateur (armorer)
###
gulp.task 'convert:coffee:bare', ()->
    files = []
    afterLast = _.once ()->
        if files? and files.length > 0
            console.log '[ ' + files.join(', ') + " ] #{files.length} files total."
    notification = {
        message: (file)->
            files.push file.relative
            string = "Converted coffee file: <%= file.relative %> "
            afterLast()
            return string
        onLast: true
    }
    destination = './lib'
    source = structure.build.paths.source.barecoffee
    stream = gulp.src source
                 .pipe coffee {bare: true}
                 # .pipe flatten()
    pipeNotification stream, notification
    stream.pipe gulp.dest destination

# convert some stylus files
gulp.task 'convert:stylus', ()->
    destination = './lib/public/css'
    files = []
    sayOnce = _.once ()->
        console.log '[ ' + files.join(', ') + ' ]'
    notification = {
        message: (file)->
            files.push file.relative
            string = "Converted stylus file: <%= file.relative %> "
            sayOnce()
            return string
        onLast: true
    }
    stream = gulp.src structure.build.paths.source.stylus
                 .on 'error', utility.log
                 .pipe stylus { compress: true }
                 .pipe prefix()
    pipeNotification stream, notification
    stream.pipe gulp.dest destination

# convert some dustjs files
gulp.task 'convert:dust', ['move', 'convert:coffee:bare'], ()->
    destination = './lib'

    dustPipe = gulp.src structure.build.paths.source.dust
                   .pipe dust()

    asJade = (path)->
        path.extname = '.jade'
        return path

    asDust = (path)->
        path.extname = '.dust'
        return path

    files = []
    sayOnce = _.once ()->
        console.log 'Powder files converted [ ' + files.join(',') + ' ]'

    notifier = (file)->
        files.push file.relative
        sayOnce()

    notifications = {
        message: notifier
        onLast: true
    }

    powderPipe = gulp.src structure.build.paths.source.powder
                     .pipe rename asJade
                     .pipe jade()
                     .pipe rename asDust
                     # .pipe notify notifications
                     .pipe dust()

    dustPowder = streamqueue({
            objectMode: true
        },
        dustPipe,
        powderPipe
    ).pipe concat './bundled-templates.js'
     .pipe gulp.dest destination

gulp.task 'build', [
    'build:templates'
]

gulp.task 'test:erase', ()->
    del [
        'test'
    ]

gulp.task 'test', [
    'test:copy-fixtures'
    'test:coffee'
], ()->
    destination = './test'
    gulp.src './test/*.js'
        .pipe mocha { reporter: 'spec', colors: true }
        .pipe gulp.dest destination

gulp.task 'clean', ()->
    del [
        'build'
        'test'
    ]

gulp.task 'build:templates', ['convert:dust'], ()->
    destination = './lib'
    sources = [
        './lib/blacksmith.js'
        './lib/bundled-templates.js'
    ]
    gulp.src sources
        .pipe concat './templates.js'
        .pipe header "(function(){\n"
        .pipe footer "\n}).call(this);"
        .pipe gulp.dest destination


gulp.task 'watch', [
    'watch:stylus'
]

gulp.task 'watch:stylus', ()->
    gulp.watch structure.build.paths.source.stylus, ['convert:stylus']

tasks = {}


# these magical options should be documented somewhere
if config?.sync?.hosts?
    rsync = require 'gulp-rsync'

    # sync data to remote host using rsync
    addSyncTask = (hostdata, hostname, x, asSingleFile=false)->
        {path, username} = hostdata
        unless path?
            path = '~/Server/raconteur'
        unless tasks?.sync?
            tasks.sync = {
                description: "Sync data to a remote host using rsync."
            }
        unless tasks?.sync?[x]?
            tasks.sync[x] = []
        if tasks?.sync?[x]? and _.isArray tasks.sync[x]
            tasks.sync[x].push hostname
        gulp.task "sync:#{x}:#{hostname}", ()->
            source = "./#{x}"

            syncSettings = {
                hostname: hostname
                destination: "#{path}/."
                times: true
                update: true
            }
            if hostdata.username?
                syncSettings.username = hostdata.username

            unless asSingleFile
                source = ["./#{x}/**/*", "./#{x}/*"]
                syncSettings.root = "./#{x}"
                syncSettings.destination = "#{path}/#{x}/."

            # shake n' bake!
            gulp.src source
                .pipe rsync syncSettings

    _(config.sync.hosts).each (hostdata, host)->
        path = hostdata.path
        if !_.isString(path) or path.length is 0
            throw new Error "Expected path to be useful."
        addFile = (x)->
            addSyncTask hostdata, host, x, true
        addFolder = (x)->
            addSyncTask hostdata, host, x

        # 'sync:gulpfile.coffee:host'
        addFile 'gulpfile.coffee'
        # 'sync:package.json:host'
        addFile 'package.json'
        # 'sync:build:host'
        addFolder 'build'
        # 'sync:config:host'
        addFolder 'config'
        # 'sync:src:host'
        addFolder 'src'
        # 'sync:views:host'
        addFolder 'views'
        # 'sync:structure:host'
        addFolder 'structure'
        # 'sync:test:host'
        addFolder 'test'

gulp.task 'tasks', ()->
    console.log _(gulp.tasks).map((value, key)->
        hash = {}
        if 0 < _.size value.dep
            hash[key] = value.dep
        return hash
    ).reduce((carrier, iter)->
        return _.extend carrier, iter
    , {})
    return

gulp.task 'default', [
    'move'
    'convert'
    'build:templates'
]