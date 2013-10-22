class TestClient extends BroadcastHubClient
    constructor: (cb) ->
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
        @disconnect(cb)

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

clients = []

window.common = common =
    send: (channel, message) ->
        callCoordinator "sendMessage", { channel: channel, message: message} , (err) ->
            throw err if err

    startServer: (options = {}, cb) ->
        if !cb
            cb = options
            options = {}
        callCoordinator "start", options, cb

    stopServer: (cb) ->
        callCoordinator "stop", cb

    start: (done) ->
        common.startServer (err, server) ->
            return done(err) if err
            common.createClient (err, client) ->
                done(err, server, client)

    stop: (done) ->
        stopClient = (client, cb) ->
            client.stop(cb)

        async.each clients, stopClient, (err) ->
            clients = []
            common.stopServer(done)

    createClient: (cb) ->
        client = new TestClient(cb)
        clients.push(client)
        return client

    clientCount: (cb) ->
        callCoordinator "clients", cb
