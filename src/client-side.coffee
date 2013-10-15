root = @ # In the browser, this will be window

SockJS = root.SockJS

throw Error('No SockJS found, be sure to include it!') if !SockJS

class BroadcastHubClient
    constructor: (@options = {}) ->
        @_listeners = {}
        @_channels = []
        @_queue = []
        @_connected = false
        @_shuttingDown = false
        @_seq = 0
        @connect()

    connect: () ->
        #throw new Error("Already have a client!") if @client
        @client = new SockJS(@options.server || "/sockets")
        @client.onopen = @_onConnected
        @client.onclose = @_onDisconnected
        @client.onmessage = @_processMessage
        ###
        @client.on 'error', @_onError

        @client.on 'connect', () =>
        ###

    on: (event, cb) ->
        return if !cb
        @_listeners[event] = [] if !@_listeners[event]
        @_listeners[event].push(cb)

    once: (event, cb) ->
        return if !cb
        wrapper = () ->
            cb.apply(@, arguments)
            @off(event, wrapper)
        @on(event, wrapper)

    off: (event, cb) ->
        return if !@_listeners[event] or cb not in @_listeners[event]
        @_listeners[event].splice(@_listeners[event].indexOf(cb), 1)

    emit: (event, args...) ->
        return if !@_listeners[event]
        for listener in @_listeners[event]
            listener.apply(@, args)

    _processMessage: (message) =>
        data = JSON.parse(message.data)
        if data.type == 'callback'
            @emit "_callback:#{data.seq}", data.err, data.data
        else
            @emit("message:#{data.channel}", data.message)
            @emit('message', data.channel, data.message)

    _onConnected: () =>
        @_connected = true
        for msg in @_queue
            @client.send(JSON.stringify(msg))
        @_queue = []

        # Resubscribe any previously-open channels
        @subscribe(channel) for channel in @_channels

    _onDisconnected: () =>
        @emit('disconnected')

        if !@_shuttingDown
            @connect()

    disconnect: (cb) ->
        @_shuttingDown = true
        @once 'disconnected', cb
        @send {
            message: 'disconnect'
        }, () =>
            @client.close()

    send: (data = {}, cb) ->
        if cb
            data._seq = @_seq++
            @once "_callback:#{data._seq}", cb
        if !@_connected
            @_queue.push(data)
        else
            @client.send(JSON.stringify(data))
        return data._seq

    subscribe: (channel, cb) ->
        @send { message: 'hubSubscribe', channel: channel }, (err) =>
            if err
                cb(err) if cb
                return
            @_channels.push(channel) if channel not in @_channels
            cb() if cb

if typeof module != 'undefined'
    # Node.js
    module.exports = BroadcastHubClient
else
    # Browsers
    root.BroadcastHubClient = BroadcastHubClient
