fs = require 'fs'
spawn = require('child_process').spawn

module.exports = (grunt) ->
    @loadNpmTasks('grunt-contrib-clean')
    @loadNpmTasks('grunt-contrib-coffee')
    @loadNpmTasks('grunt-contrib-jshint')
    @loadNpmTasks('grunt-contrib-uglify')
    @loadNpmTasks('grunt-contrib-watch')
    @loadNpmTasks('grunt-mocha-cli')
    @loadNpmTasks('grunt-karma')
    @loadNpmTasks('grunt-release')

    @initConfig
        jshint:
            all: ["example/*.js", "test/*.js"]
            options:
                jshintrc: ".jshintrc"

        coffee:
            server:
                options:
                    bare: true
                expand: true
                cwd: 'src'
                src: ['*.coffee', '!client-side.coffee']
                dest: 'lib'
                ext: '.js'
            client:
                files:
                    'broadcast-hub-client.js': ['src/client-side.coffee']

        uglify:
            dist:
                files:
                    'broadcast-hub-client.min.js': 'broadcast-hub-client.js'

        clean:
            all: ['lib', 'tmp']

        doWatch:
            all:
                options:
                    spawn: false
                files: ['src/**.coffee', 'test/**.coffee']
                tasks: ['build', 'testserver', 'karma:watch:run']

        mochacli:
            options:
                files: 'test/*_test.coffee'
                compilers: ['coffee:coffee-script']
            spec:
                options:
                    reporter: 'spec'
                    slow: 150

        karma:
            unit:
                configFile: 'test/configs/unit.conf.coffee'
            watch:
                configFile: 'test/configs/unit.conf.coffee'
                background: true
                singleRun: false
                browsers: ['PhantomJS']

    @registerTask 'testserver', 'Test coordination server', () ->
        done = @async()

        pid = __dirname + '/test/server/server.pid'
        if fs.existsSync(pid)
            try
                process.kill(fs.readFileSync(pid, 'utf8'))
            fs.unlinkSync(pid)

        # Start new server
        signalled = false
        server = spawn 'coffee', ['test/server/server.coffee'], { stdio: ['ignore', 'pipe', 'pipe' ] }
        server.stdout.on 'data', (data) ->
            if /## Starting test coordinator/.test(data.toString()) && !signalled
                signalled = true
                done()
                return
            grunt.log.write(data.toString())
        server.stderr.on 'data', (data) ->
            grunt.log.error(data.toString())
        fs.writeFileSync(pid, server.pid)

    @renameTask 'watch', 'doWatch'

    @registerTask 'default', ['test']
    @registerTask 'build', ['clean', 'coffee', 'jshint', 'uglify']
    @registerTask 'package', ['build', 'release']
    @registerTask 'test', ['build', 'testserver', 'karma:unit']
    @registerTask 'watch', ['karma:watch', 'doWatch']
