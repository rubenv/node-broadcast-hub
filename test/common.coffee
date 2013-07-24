assert = require 'assert'
redis = require 'redis'
redisClient = redis.createClient()
express = require 'express'
socketIoClient = require 'socket.io-client'
broadcastHub = require '..'

class Client
    constructor: (@server, cb) ->
        @messages = []
        @waiting = []

        @client = socketIoClient.connect("http://localhost:#{@server.port}", {
            'force new connection': true
        })
        @client.on 'event', @processMessage
        @client.on 'connect', cb
        
    waitForMessage: (channel, message, cb) ->
        @waiting.push(arguments)

    processMessage: (message) =>
        for [channel, body, cb] in @waiting
            if message.channel == channel && message.message == body
                cb()

    stop: () ->
        @client.disconnect()


common = module.exports =
    send: (channel, message) ->
        redisClient.publish channel, message

    startServer: (cb) ->
        server = express()
        server.port = Math.floor(Math.random() * 10000) + 40000
        server.http = server.listen(server.port)
        broadcastHub.listen server.http, (err) ->
            return cb(err) if err
            cb(null, server)
        return server

    stopServer: (server) ->
        server.http.close()

    start: (done) ->
        server = common.startServer (err) ->
            return done(err) if err
            client = common.createClient server, (err) ->
                done(err, server, client)

    stop: (server, client) ->
        common.stopServer(server)
        client.stop()

    createClient: (server, cb) ->
        return new Client(server, cb)
