redis = require 'redis'

class Client
    constructor: (@hub, @id, @socket) ->
        @redis = redis.createClient()
        @redis.on 'message', @onMessage

        @socket.on 'disconnect', @onDisconnect
        @socket.on 'hubSubscribe', @onSubscribe

    onMessage: (channel, message) =>
        @socket.emit 'hubMessage',
            channel: channel
            message: message

    onSubscribe: (channel, cb) =>
        @redis.subscribe channel, cb

    disconnect: () ->
        @socket.disconnect()

    onDisconnect: () =>
        @hub.disconnect(@)
        @redis.quit()

module.exports = Client
