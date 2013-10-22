describe 'Authentication', ->
    afterEach(common.stop)

    it 'Authorized clients can connect', (done) ->
        common.startServer { scenario: 'auth-allow' }, (err) ->
            return done(err) if err
            common.createClient (err) ->
                return done(err) if err

                common.serverInfo (err, info) ->
                    return done(err) if err
                    assert.equal(info.calls, 1)
                    done()

    it 'Unauthorized clients cannot connect', (done) ->
        common.startServer { scenario: 'auth-deny' }, (err) ->
            return done(err) if err
            client = common.createClient()
            client.on 'error', (err) =>
                assert.equal(err, 'handshake unauthorized')

                common.serverInfo (err, info) ->
                    return done(err) if err
                    assert.equal(info.calls, 1)
                    done()

    it 'Server can authenticate channels', (done) ->
        common.startServer { scenario: 'channel-allow' }, (err) ->
            return done(err) if err
            client = common.createClient()
            client.subscribe 'test', (err) ->
                return done(err) if err

                common.serverInfo (err, info) ->
                    return done(err) if err
                    assert.equal(info.calls, 2) # Two: Also for the test channel
                    done()

    it 'Server can refuse channel subscriptions', (done) ->
        common.startServer { scenario: 'channel-deny' }, (err) ->
            return done(err) if err
            common.createClient (err, client) =>
                return done(err) if err

                client.subscribe 'test', (err) ->
                    common.serverInfo (ierr, info) ->
                        return done(ierr) if ierr

                        assert.equal(info.calls, 2) # Two: Also for the test channel
                        assert.equal('subscription refused', err)
                        done()
