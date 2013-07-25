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
        @hub.canSubscribe @, channel, (err, allowed) =>
            return cb(err) if err
            return cb('subscription refused') if !allowed

            @redis.subscribe channel, (err) ->
                return if !cb
                return cb(err, channel)

    disconnect: () ->
        @socket.disconnect()

    onDisconnect: () =>
        @hub.disconnect(@)
        @redis.quit()

module.exports = Client
