describe 'Relay', ->
    beforeEach (done) ->
        common.start (err, @server, @client) => done(err)

    afterEach(common.stop)

    it 'A redis message is relayed to the client', (done) ->
        @client.waitForMessage('public-test', 'test', done)
        common.send('public-test', 'test')

    it 'Multiple clients all receive the message', (done) ->
        client2 = common.createClient (err) =>
            return done(err) if err
            common.send('public-test', 'multiple')

            async.parallel [
                (cb) => @client.waitForMessage('public-test', 'multiple', cb)
                (cb) => client2.waitForMessage('public-test', 'multiple', cb)
            ], done

    it 'Server handles disconnects', (done) ->
        common.clientCount (err, count) =>
            assert.equal(count, 1, 'After start')
            common.createClient (err, client2) =>
                return done(err) if err

                common.clientCount (err, count) =>
                    assert.equal(count, 2, 'After connect')

                    common.send('public-test', 'test')

                    async.parallel [
                        (cb) => @client.waitForMessage('public-test', 'test', cb)
                        (cb) => client2.waitForMessage('public-test', 'test', cb)
                    ], (err) =>
                        return done(err) if err

                        client2.stop (err) =>
                            return done(err) if err

                            common.clientCount (err, count) =>
                                assert.equal(count, 1, 'After disconnect')

                                @client.waitForMessage 'public-test', 'test', () ->
                                    common.clientCount (err, count) ->
                                        assert.equal(count, 1, 'After message')
                                        done()

                                common.send('public-test', 'test')

