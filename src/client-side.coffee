# Utilities
noop = () ->
after = (timeout, cb) -> setTimeout(cb, timeout)


root = @ # In the browser, this will be window

SockJS = root.SockJS

throw Error('No SockJS found, be sure to include it!') if !SockJS

class BroadcastHubClient
    constructor: (@options = {}) ->
        @_listeners = {}
        @_channels = []
        @_queue = []
        @_connected = false
        @_attempt = 0
        @_seq = 0
        @connect()

    connect: () =>
        @_shuttingDown = false
        @_attempt = Math.min(@_attempt + 1, 20)
        throw new Error("Already have a client!") if @client
        @client = new SockJS(@options.server || "/sockets")
        @client.onopen = @_onConnected
        @client.onclose = @_onDisconnected
        @client.onmessage = @_processMessage

    ###
    # Event emitter methods
    ###
    
    on: (event, cb) ->
        return if !cb
        @_listeners[event] = [] if !@_listeners[event]
        @_listeners[event].push(cb)

    once: (event, cb) ->
        return if !cb
        wrapper = () =>
            cb.apply(@, arguments)
            @off(event, wrapper)
        @on(event, wrapper)

    off: (event, cb) ->
        return if !@_listeners[event] or cb not in @_listeners[event]
        @_listeners[event].splice(@_listeners[event].indexOf(cb), 1)

    emit: (event, args...) ->
        return if !@_listeners[event]
        # Make a copy to prevent issues when a listener calls @off (e.g. with
        # @once).
        listeners = @_listeners[event].slice(0)
        for listener in listeners
            listener.apply(@, args)
        return

    ###
    # Internal methods
    ###

    _processMessage: (message) =>
        data = JSON.parse(message.data)
        if data.type == 'callback'
            @emit "_callback:#{data.seq}", data.err, data.data
        else
            @emit("message:#{data.channel}", data.message)
            @emit('message', data.channel, data.message)

    _handshake: (cb) ->
        @send { message: 'hubConnect', data: @options.auth || {} }, cb

    _onConnected: () =>
        @_attempt = 0
        @_connected = true
        @_handshake (err) =>
            return @emit('error', err) if err
            @client.send(msg) for msg in @_queue
            @_queue = []

            emitConnected = () =>
                @emit('connected') if toSubscribe == 0

            # Resubscribe any previously-open channels
            toSubscribe = @_channels.length
            for channel in @_channels
                @subscribe channel, (err) ->
                    toSubscribe -= 1
                    emitConnected()

            # The for loop won't be executed if there are not channels to subscribe
            # to, call once more to make sure we always have a 'connected'-signal
            # emitted.
            emitConnected()

    _onDisconnected: () =>
        @client.onopen = null
        @client.onclose = null
        @client.onmessage = null
        @client = null
        @_connected = false
        @emit('disconnected')

        # Retry after a while.
        if !@_shuttingDown
            after @_attempt * 250, @connect

    ###
    # External API
    ###
    
    disconnect: (cb = noop) ->
        @_shuttingDown = true
        return cb() if !@_connected
        @once 'disconnected', cb
        @send { message: 'disconnect' }, () =>
            @client.close()

    ###
        Send some data back to the server.

        Optionally accepts a callback function. When supplied, an extra _seq
        field will be sent to the server, this can then be used server-side to
        reply to the message. Typical use-case is returning the result of
        authenticate / subscribe.
    ###
    send: (data = {}, cb) ->
        if cb
            data._seq = @_seq++
            @once "_callback:#{data._seq}", cb
        payload = JSON.stringify(data)
        if !@_connected
            @_queue.push(payload)
        else
            @client.send(payload)
        return data._seq

    subscribe: (channel, cb = noop) ->
        @send { message: 'hubSubscribe', channel: channel }, (err) =>
            return cb(err) if err
            @_channels.push(channel) if channel not in @_channels
            cb()

root.BroadcastHubClient = BroadcastHubClient
