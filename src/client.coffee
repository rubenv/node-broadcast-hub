redis = require 'redis'

class Client
    constructor: (@hub, @id, @socket) ->
        @redis = redis.createClient()
        @redis.on 'pmessage', @onPMessage
        @redis.psubscribe '*', (err) =>
            # TODO: if err
            @socket.emit 'hubSubscribed'

        @socket.on 'disconnect', @onDisconnect

    onPMessage: (pattern, channel, message) =>
        @socket.emit 'hubMessage',
            channel: channel
            message: message

    onDisconnect: () =>
        @hub.disconnect(@)
        @redis.quit()

module.exports = Client
