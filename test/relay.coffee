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
        common.stopServer(server)

    it 'A redis message is relayed to the client', (done) ->
        client.waitForMessage 'public-test', 'test', done
        common.send 'public-test', 'test'
