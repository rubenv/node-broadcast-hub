redis = require 'redis'
sockjs = require 'sockjs'

{defaults} = require './utils'

Client = require './client'

class BroadcastHub
    constructor: (@server, @options = {}) ->
        # Clients are tracked in a hash, this gives us O(1) disconnects.
        @clients = {}
        @clientId = 0

        # Defaults for options
        defaults(@options, {
            redisHost: '127.0.0.1'
            redisPort: 6379
            publishHost: @options.redisHost || '127.0.0.1'
            publishPort: @options.redisPort || 6379
        })

        # Channels
        @channels = {}

        # Open a sockjs listener and listen for new clients.
        @socket = sockjs.createServer({
            log: @options.log || () ->
        })
        @socket.installHandlers(@server, { prefix: @options.prefix || '/sockets' })
        @socket.on 'connection', @onSocketConnect

    onSocketConnect: (socket) =>
        @clients[@clientId] = new Client(@, @clientId, socket)
        @clientId += 1

    disconnect: (client) ->
        delete @clients[client.id]

    disconnectAll: () ->
        client.disconnect() for id, client of @clients
        @clients = {}

    canConnect: (client, data, cb) ->
        return cb(null, true) if !@options.canConnect
        @options.canConnect(client, data, cb)

    canSubscribe: (client, channel, cb) ->
        return cb(null, true) if !@options.canSubscribe
        @options.canSubscribe(client, channel, cb)

    publish: (channel, message, cb) ->
        if !@publishClient
            @publishClient = redis.createClient(@options.publishPort, @options.publishHost) 
            if @options.publishAuth
                @publishClient.auth(@options.publishAuth);

        @publishClient.publish(channel, message, cb)

    # Counting clients is O(n), but that's okay, it's a diagnostic thing for
    # testing anyway.
    Object.defineProperty @prototype, 'clientCount',
        get: () ->
            clients = 0
            clients += 1 for key of @clients
            return clients

module.exports = BroadcastHub
