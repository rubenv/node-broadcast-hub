{after} = require './utils'

Channel = require './channel'

class Client
    constructor: (@hub, @id, @socket) ->
        @authenticated = false
        @channels = []
        @data = {}

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

    relay: (channel, message) =>
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

    onSubscribe: (name, cb) =>
        return cb('handshake required') if !@authenticated

        @hub.canSubscribe @, name, (err, allowed) =>
            return cb(err) if err
            return cb('subscription refused') if !allowed

            Channel.get name, (err, channel) =>
                return cb(err) if err
                channel.subscribe(@)
                @channels.push(channel)
                cb()

    disconnect: () ->
        @onDisconnect()
        @socket.close()

    onDisconnect: () =>
        @hub.disconnect(@) if @hub
        @hub = null

        for channel in @channels
            channel.unsubscribe(@)
        @channels = null

    checkAuthenticated: () =>
        if !@authenticated
            @disconnect()

module.exports = Client
