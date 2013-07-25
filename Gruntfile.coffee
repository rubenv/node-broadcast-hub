module.exports = (grunt) ->
    @loadNpmTasks('grunt-contrib-clean')
    @loadNpmTasks('grunt-contrib-coffee')
    @loadNpmTasks('grunt-contrib-jshint')
    @loadNpmTasks('grunt-contrib-uglify')
    @loadNpmTasks('grunt-contrib-watch')
    @loadNpmTasks('grunt-mocha-cli')
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
                expand: true,
                cwd: 'src',
                src: ['*.coffee', '!client-side.coffee'],
                dest: 'lib',
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

        watch:
            all:
                files: ['src/**.coffee', 'test/**.coffee']
                tasks: ['test']

        mochacli:
            options:
                files: 'test/*_test.coffee'
                compilers: ['coffee:coffee-script']
            spec:
                options:
                    reporter: 'spec'
                    slow: 150

    @registerTask 'default', ['test']
    @registerTask 'build', ['clean', 'coffee', 'jshint', 'uglify']
    @registerTask 'package', ['build', 'release']
    @registerTask 'test', ['build', 'mochacli']
