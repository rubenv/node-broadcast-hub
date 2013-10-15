autoquit = require 'autoquit'
express = require 'express'
broadcastHub = require '../..'

app = express()
http = app.listen(9875)
http.autoQuit()
hub = broadcastHub.listen(http, {
    log: (level, msg) ->
        console.log "#{level}: #{msg}"
})

app.get '/clients', (req, res, next) ->
    res.json(hub.clientCount)
