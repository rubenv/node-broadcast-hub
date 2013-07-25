assert = require 'assert'
async = require 'async'
common = require './common'

describe 'Relay', ->
    beforeEach (done) ->
        common.start (err, @server, @client) => done(err)

    afterEach ->
        common.stop(@server, @client)

    it 'A redis message is relayed to the client', (done) ->
        @client.waitForMessage('public-test', 'test', done)
        common.send('public-test', 'test')

    it 'Multiple clients all receive the message', (done) ->
        client2 = common.createClient @server, (err) =>
            return done(err) if err
            common.send('public-test', 'test')

            async.parallel [
                (cb) => @client.waitForMessage('public-test', 'test', cb)
                (cb) => client2.waitForMessage('public-test', 'test', cb)
            ], done

    it 'Server handles disconnects', (done) ->
        client2 = common.createClient @server, (err) =>
            return done(err) if err
            common.send('public-test', 'test')

            assert.equal(@server.hub.clientCount, 2)

            async.parallel [
                (cb) => @client.waitForMessage('public-test', 'test', cb)
                (cb) => client2.waitForMessage('public-test', 'test', cb)
            ], (err) =>
                return done(err) if err

                client2.stop (err) =>
                    return done(err) if err
                    assert.equal(@server.hub.clientCount, 1)
                    @client.waitForMessage('public-test', 'test', done)
                    common.send('public-test', 'test')
                    assert.equal(@server.hub.clientCount, 1)
