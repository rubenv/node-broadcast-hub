assert = require 'assert'
redis = require 'redis'
redisClient = redis.createClient()
express = require 'express'
broadcastHub = require '..'
BroadcastHubClient = require '../broadcast-hub-client'

class TestClient extends BroadcastHubClient
    constructor: (@server, cb) ->
        super({
            server: "http://localhost:#{@server.port}"
        })
        @waiting = []

        @on 'connected', cb
        @on 'message', @processMessage
        
    waitForMessage: (channel, message, cb) ->
        @waiting.push(arguments)

    processMessage: (channel, body) =>
        for wait in @waiting
            [wchannel, wbody, cb] = wait
            if channel == wchannel && body == wbody
                @waiting.splice(@waiting.indexOf(wait), 1) # Remove from list
                return cb()

    stop: (cb) ->
        if cb
            @on 'disconnected', () ->
                # Give the server some time to clean this up
                setTimeout cb, 5
        @disconnect()

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
