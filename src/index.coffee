socketIo = require 'socket.io'
redis = require 'redis'

class BroadcastHub
    constructor: (@server, cb) ->
        @connections = []
        @io = socketIo.listen(@server, {
            'log level': 1
        })
        @io.sockets.on 'connection', @onSocketConnect

        @redis = redis.createClient()
        @redis.on 'pmessage', @onPMessage
        @redis.psubscribe '*', cb

    onSocketConnect: (socket) =>
        @connections.push(socket)

    onPMessage: (pattern, channel, message) =>
        for connection in @connections
            connection.emit 'event',
                channel: channel
                message: message

module.exports =
    listen: (server, cb) ->
        return new BroadcastHub(server, cb)
