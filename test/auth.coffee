describe.skip 'Authentication', ->
    afterEach(common.stop)

    it 'Authorized clients can connect', (done) ->
        calls = 0
        options =
            canConnect: (data, cb) ->
                calls++
                cb(null, true)
        common.startServer options, (err) ->
            return done(err) if err
            common.createClient (err) =>
                return done(err) if err
                assert.equal(calls, 1)
                done()

    it 'Unauthorized clients cannot connect', (done) ->
        calls = 0
        options =
            canConnect: (data, cb) ->
                calls++
                cb(null, false)
        common.startServer options, (err) ->
            return done(err) if err
            common.createClient (err, client) =>
                return done(err) if err
                client.on 'error', (err) =>
                    assert.equal(calls, 1)
                    assert.equal(err, 'handshake unauthorized')
                    done()

    it 'Server can authenticate channels', (done) ->
        calls = 0
        options =
            canSubscribe: (data, channel, cb) ->
                calls++
                cb(null, true)
        common.startServer options, (err) ->
            return done(err) if err
            common.createClient (err, client) =>
                return done(err) if err
                client.subscribe 'test', (err) ->
                    return done(err) if err
                    assert.equal(calls, 2) # Two: Also for the test channel
                    done()

    it 'Server can refuse channel subscriptions', (done) ->
        calls = 0
        options =
            canSubscribe: (data, channel, cb) ->
                calls++
                cb(null, false)
        common.startServer options, (err) ->
            return done(err) if err
            common.createClient (err, client) =>
                return done(err) if err
                client.subscribe 'test', (err) ->
                    assert.equal(calls, 2) # Two: Also for the test channel
                    assert.equal('subscription refused', err)
                    done()
