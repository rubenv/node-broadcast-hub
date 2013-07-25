assert = require 'assert'
redis = require 'redis'
redisClient = redis.createClient()
express = require 'express'
socketIoClient = require 'socket.io-client'
broadcastHub = require '..'

class TestClient
    constructor: (@server, cb) ->
        @messages = []
        @waiting = []

        @client = socketIoClient.connect("http://localhost:#{@server.port}", {
            'force new connection': true
        })
        @client.on 'hubMessage', @processMessage
        @client.on 'hubSubscribed', cb
        
    waitForMessage: (channel, message, cb) ->
        @waiting.push(arguments)

    processMessage: (message) =>
        for wait in @waiting
            [channel, body, cb] = wait
            if message.channel == channel && message.message == body
                @waiting.splice(@waiting.indexOf(wait), 1) # Remove from list
                return cb()

    stop: (cb) ->
        if cb
            @client.on 'disconnect', () ->
                # Give the server some time to clean this up
                setTimeout cb, 5
        @client.disconnect()

common = module.exports =
    send: (channel, message) ->
        redisClient.publish channel, message

    startServer: () ->
        server = express()
        server.port = Math.floor(Math.random() * 10000) + 40000
        server.http = server.listen(server.port)
        server.hub = broadcastHub.listen(server.http)
        return server

    stopServer: (server) ->
        server.http.close()

    start: (done) ->
        server = common.startServer()
        client = common.createClient server, (err) ->
            done(err, server, client)

    stop: (server, client) ->
        common.stopServer(server)
        client.stop()

    createClient: (server, cb) ->
        return new TestClient(server, cb)
