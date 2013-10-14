redis = require 'redis'

class Client
    constructor: (@hub, @id, @socket) ->
        @redis = redis.createClient()
        @redis.on 'message', @onMessage

        @socket.on 'close', @onDisconnect
        #@socket.on 'hubSubscribe', @onSubscribe

        @socket.on 'data', @onData

    callback: (id) =>
        return (err, data) =>
            @socket.write(JSON.stringify({
                type: 'callback'
                seq: id
                err: err
                data: data
            }))

    onData: (data) =>
        obj = JSON.parse(data)

        if obj.message == 'hubSubscribe'
            @onSubscribe obj.channel, @callback(obj._seq)
        else if obj.message == 'disconnect'
            @disconnect()

    onMessage: (channel, message) =>
        @socket.write(JSON.stringify({
            type: 'message'
            channel: channel
            message: message
        }))

    onSubscribe: (channel, cb) =>
        @hub.canSubscribe @, channel, (err, allowed) =>
            return cb(err) if err
            return cb('subscription refused') if !allowed

            @redis.subscribe channel, (err) ->
                return if !cb
                return cb(err, channel)

    disconnect: () ->
        @onDisconnect()
        @socket.close()

    onDisconnect: () =>
        @hub.disconnect(@) if @hub
        @redis.quit() if @redis

        @hub = null
        @redis = null

module.exports = Client
