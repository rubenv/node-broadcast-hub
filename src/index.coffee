BroadcastHub = require './hub'

module.exports =
    listen: (server, options) ->
        return new BroadcastHub(server, options)
