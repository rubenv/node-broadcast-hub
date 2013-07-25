BroadcastHub = require './hub'

module.exports =
    listen: (server) ->
        return new BroadcastHub(server)
