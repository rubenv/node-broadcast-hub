class TestClient extends BroadcastHubClient
    constructor: (@server, cb) ->
        super({
            server: 'http://localhost:9875/sockets'
            log: () ->
        })
        @waiting = []

        @on 'message', @processMessage
        @subscribe 'public-test', (err) =>
            cb(err, @)

    waitForMessage: (channel, message, cb) ->
        @waiting.push(arguments)

    processMessage: (channel, body) =>
        for wait in @waiting
            [wchannel, wbody, cb] = wait
            if channel == wchannel && body == wbody
                @waiting.splice(@waiting.indexOf(wait), 1) # Remove from list
                return cb()

    stop: (cb) ->
        if cb
            @on 'disconnected', () ->
                # Give the server some time to clean this up
                setTimeout cb, 5
        @disconnect()

callCoordinator = (action, data, cb) ->
    if !cb
        cb = data
        data = {}

    superagent
        .post("/coordinate/#{action}")
        .send(data)
        .end (res) ->
            if !res.ok
                cb(new Error("Coordinator call failed: #{action}: #{JSON.stringify(data)}"))
            else
                cb(null, res.body)

server = null

window.common = common =
    send: (channel, message) ->
        callCoordinator "sendMessage", { channel: channel, message: message} , (err) ->
            throw err if err

    startServer: (options = {}, cb) ->
        if !cb
            cb = options
            options = {}
        callCoordinator "start", options, cb

    stopServer: (server, cb) ->
        callCoordinator "stop", cb

    start: (done) ->
        common.startServer (err, s) ->
            return done(err) if err
            server = s
            common.createClient server, (err, client) ->
                done(err, server, client)

    stop: (server, client, done) ->
        client.stop() if client
        common.stopServer(server, done)

    createClient: (server, cb) ->
        return new TestClient(server, cb)

    clientCount: (cb) ->
        callCoordinator "clients", cb
