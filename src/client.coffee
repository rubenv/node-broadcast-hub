redis = require 'redis'

{after} = require './utils'

class Client
    constructor: (@hub, @id, @socket) ->
        @authenticated = false
        @redis = redis.createClient()
        @redis.on 'message', @onMessage

        @socket.on 'close', @onDisconnect
        @socket.on 'data', @onData

        after 10 * 1000, @checkAuthenticated

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

        if obj.message == 'hubConnect'
            @onConnect obj.data, @callback(obj._seq)
        else if obj.message == 'hubSubscribe'
            @onSubscribe obj.channel, @callback(obj._seq)
        else if obj.message == 'disconnect'
            @disconnect()

    onMessage: (channel, message) =>
        @socket.write(JSON.stringify({
            type: 'message'
            channel: channel
            message: message
        }))

    onConnect: (data, cb) =>
        @hub.canConnect @, data, (err, allowed) =>
            return cb(err) if err

            if !allowed
                cb('handshake unauthorized')
            else
                @authenticated = true
                cb()

    onSubscribe: (channel, cb) =>
        return cb('handshake required') if !@authenticated

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

    checkAuthenticated: () =>
        if !@authenticated
            @disconnect()

module.exports = Client
