async = require 'async'
common = require './common'

describe 'Relay', ->
    server = null
    client = null

    beforeEach (done) ->
        common.start (err, s, c) ->
            server = s
            client = c
            done(err)

    afterEach ->
        common.stop(server, client)

    it 'A redis message is relayed to the client', (done) ->
        client.waitForMessage 'public-test', 'test', done
        common.send 'public-test', 'test'

    it 'Multiple clients all receive the message', (done) ->
        client2 = common.createClient server, (err) ->
            return done(err) if err
            common.send 'public-test', 'test'

            async.parallel [
                (cb) -> client.waitForMessage 'public-test', 'test', cb
                (cb) -> client2.waitForMessage 'public-test', 'test', cb
            ], done
