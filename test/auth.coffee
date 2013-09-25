assert = require 'assert'
common = require './common'

describe 'Authentication', ->
    afterEach ->
        common.stop(@server, @client)

    it 'Authorized clients can connect', (done) ->
        calls = 0
        options =
            canConnect: (data, cb) ->
                calls++
                cb(null, true)
        @server = common.startServer(options)
        @client = common.createClient @server, (err) =>
            return done(err) if err
            assert.equal(calls, 1)
            done()

    it 'Unauthorized clients cannot connect', (done) ->
        calls = 0
        options =
            canConnect: (data, cb) ->
                calls++
                cb(null, false)
        @server = common.startServer(options)
        client = common.createClient(@server)
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
        @server = common.startServer(options)
        client = common.createClient(@server)
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
        @server = common.startServer(options)
        client = common.createClient(@server)
        client.subscribe 'test', (err) ->
            assert.equal(calls, 2) # Two: Also for the test channel
            assert.equal('subscription refused', err)
            done()
