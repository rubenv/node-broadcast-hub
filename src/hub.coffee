socketIo = require 'socket.io'

Client = require './client'

class BroadcastHub
    constructor: (@server) ->
        # Clients are tracked in a hash, this gives us O(1) disconnects.
        @clients = {}
        @clientId = 0

        # Open a socket.io listener and listen for new clients.
        @io = socketIo.listen(@server, {
            'log level': 1
        })
        @io.sockets.on 'connection', @onSocketConnect

    onSocketConnect: (socket) =>
        @clients[@clientId] = new Client(@, @clientId, socket)
        @clientId += 1

    disconnect: (client) ->
        delete @clients[client.id]

    disconnectAll: () ->
        client.disconnect() for id, client of @clients
        @clients = {}

    # Counting clients is O(n), but that's okay, it's a diagnostic thing for
    # testing anyway.
    Object.defineProperty @prototype, 'clientCount',
        get: () ->
            clients = 0
            clients += 1 for key of @clients
            return clients

module.exports = BroadcastHub
