root = @ # In the browser, this will be window

io = root.io
if !io && typeof require != 'undefined'
    io = require 'socket.io-client'

throw Error('No Socket.IO found, be sure to include it!') if !io

class BroadcastHubClient
    constructor: (@options = {}) ->
        @_listeners = {}

        @client = io.connect(options.server, {
            'force new connection': true
        })
        @client.on 'hubMessage', @_processMessage
        @client.on 'hubSubscribed', () => @emit('connected')
        @client.on 'disconnect', @_onDisconnected

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
        @emit('message', message.channel, message.message)
        @emit("message:#{message.channel}", message.message)

    _onDisconnected: (reason) =>
        @emit('disconnected')
        if reason != 'booted'
            # TODO: Trigger reconnect
            console.log arguments

    disconnect: (cb) ->
        @once 'disconnected', cb
        @client.disconnect()

if typeof module != 'undefined'
    # Node.js
    module.exports = BroadcastHubClient
else
    # Browsers
    root.BroadcastHubClient = BroadcastHubClient
