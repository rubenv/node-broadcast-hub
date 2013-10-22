describe 'Channels', ->
    beforeEach (done) ->
        common.start (err, @server, @client) => done(err)

    afterEach(common.stop)

    it 'Clients can subscribe to channels', (done) ->
        @client.subscribe('test', done)

    it 'Client receives messages from channel after subscribing', (done) ->
        calls = 0
        callsChannel = 0

        @client.on 'message:public-channel', () ->
            callsChannel += 1
        @client.on 'message', (channel) =>
            calls += 1

            if calls == 1
                # First message
                assert.equal(channel, 'public-test')
                assert.equal(callsChannel, 0)
                @client.subscribe 'public-channel', (err) ->
                    return done(err) if err
                    common.send('public-channel', 'test')
            else if calls == 2
                assert.equal(channel, 'public-channel')
                assert.equal(callsChannel, 1)
                done()

        common.send('public-channel', 'test') # Will not arrive
        common.send('public-test', 'test') # Will arrive

    it 'Only subscribed clients receive messages from a channel', (done) ->
        calls = 0
        callsChannel = 0

        countMessage = (channel) ->
            calls++ if channel == 'public-test'
            callsChannel++ if channel == 'public-channel'

            if calls == 2
                assert.equal(callsChannel, 1)
                done()

        client2 = common.createClient @server, (err) =>
            return done(err) if err

            @client.on 'message', countMessage
            client2.on 'message', countMessage

            @client.subscribe 'public-channel', (err) =>
                return done(err) if err

                common.send('public-channel', 'test') # Will arrive at one client
                common.send('public-test', 'test') # Will arrive at both clients

    it 'Client resubscribes to channels after disconnect', (done) ->
        port = @server.port
        @client.subscribe 'public-channel', (err) =>
            return done(err) if err

            common.stopServer (err) =>
                return done(err) if err
                # Start new server and manually trigger a reconnect
                # In event of a failure, socket.io will retry automatically,
                # but not in this case, it's a clean shutdown.

                disconnect = false
               
                calls = 0
                @client.on 'message', () ->
                    calls++
                    assert.equal(disconnect, true)
                    done() if calls == 2

                @client.on 'disconnected', () ->
                    disconnect = true

                @client.on 'connected', () ->
                    common.send('public-channel', 'test')
                    common.send('public-test', 'test')
                
                common.startServer (err, @server) =>
                    return done(err) if err
