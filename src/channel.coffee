redis = require 'redis'

channels = {}

class Channel
    @get: (hub, name, cb) ->
        if channels[name]
            return cb(null, channels[name])

        channel = channels[name] = new Channel(hub, name)
        channel.prepare (err) ->
            cb(err, channel)

    constructor: (@hub, @name) ->
        @clients = []

        @redis = redis.createClient(@hub.options.redisPort, @hub.options.redisHost)
        if @hub.options.redisAuth
            @redis.auth(@hub.options.redisAuth);

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

        return

    onMessage: (channel, message) =>
        for client in @clients
            client.relay(channel, message)
        return

module.exports = Channel
