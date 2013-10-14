module.exports = (config) ->
    config.set
        basePath: '../..'
        files: [
            'node_modules/superagent/superagent.js'
            'node_modules/async/lib/async.js'
            'bower_components/sockjs/sockjs.js'
            'broadcast-hub-client.js'
            'test/*.coffee'
        ]
        frameworks: ['chai', 'mocha']
        urlRoot: '/karma/'
        #browsers: ['PhantomJS']
        browsers: ['Chrome']
        reporters: ['dots']
        port: 9877
        singleRun: true
        proxies:
            '/coordinate': 'http://localhost:9876'
