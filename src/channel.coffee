redis = require 'redis'

channels = {}

class Channel
    @get: (name, cb) ->
        if channels[name]
            return cb(null, channels[name])

        channel = channels[name] = new Channel(name)
        channel.prepare (err) ->
            cb(err, channel)

    constructor: (@name) ->
        @clients = []

        @redis = redis.createClient()
        @redis.on 'message', @onMessage

    prepare: (cb) ->
        @redis.subscribe(@name, cb)

    subscribe: (client) ->
        @clients.push(client)

    unsubscribe: (client) ->
        index = @clients.indexOf(client)
        return if index < 0
        @clients.splice(index, 1)

        if @clients.length == 0
            @redis.unsubscribe(@name)
            @redis.quit()
            delete channels[@name]

    onMessage: (channel, message) =>
        for client in @clients
            client.relay(channel, message)

module.exports = Channel
