describe 'Client', ->
    beforeEach (done) ->
        common.start (err, @server, @client) => done(err)

    afterEach (done) ->
        common.stop(@server, @client, done)

    it 'Client can listen for all messages', (done) ->
        @client.on 'message', () -> done()
        common.send('public-test', 'test')

    it 'Client can have multiple listeners', (done) ->
        calls = 0
        @client.on 'message', () ->
            calls += 1
            done() if calls == 2
        @client.on 'message', () ->
            calls += 1
            done() if calls == 2
        common.send('public-test', 'test')

    it 'Client can listen for messages of specific channel', (done) ->
        @client.on 'message:public-test', () -> done()
        common.send('public-test', 'test')

    it 'Client sends both message signals', (done) ->
        calls = 0
        @client.on 'message', () ->
            calls += 1
            done() if calls == 2
        @client.on 'message:public-test', () ->
            calls += 1
            done() if calls == 2
        common.send('public-test', 'test')

    it 'Client can listen for a message once', (done) ->
        calls = 0
        @client.once 'message', () =>
            calls++

            # If another message comes in: mark as done
            @client.on 'message', () ->
                assert.equal(calls, 1)
                done()
        common.send('public-test', 'test')
        common.send('public-test', 'test')

    it 'Client can track disconnects through signal', (done) ->
        @client.once 'disconnected', done
        @client.disconnect()

    it 'Client can disconnect manually and get callback', (done) ->
        @client.disconnect(done)

    it 'Client can disconnect listeners', (done) ->
        calls = 0
        handler = () =>
            calls++

            @client.off 'message', handler
            @client.on 'message', () ->
                assert.equal(calls, 1)
                done()

            common.send('public-test', 'test')

        @client.on 'message', handler

        common.send('public-test', 'test')
