autoquit = require 'autoquit'
express = require 'express'
broadcastHub = require '../..'

app = express()
http = app.listen(9875)
http.autoQuit()

info = {}

options = {
    log: (level, msg) ->
        console.log "#{level}: #{msg}"
}

startOptions = JSON.parse(process.argv[2] || "{}")

if startOptions.scenario == 'auth-allow'
    info.calls = 0
    options.canConnect = (client, data, cb) ->
        info.calls++
        cb(null, true)

if startOptions.scenario == 'auth-deny'
    info.calls = 0
    options.canConnect = (client, data, cb) ->
        info.calls++
        cb(null, false)

if startOptions.scenario == 'channel-allow'
    info.calls = 0
    options.canSubscribe = (client, channel, cb) ->
        info.calls++
        cb(null, true)

if startOptions.scenario == 'channel-deny'
    info.calls = 0
    options.canSubscribe = (client, channel, cb) ->
        info.calls++
        cb(null, channel == 'public-test')

hub = broadcastHub.listen(http, options)

app.get '/clients', (req, res, next) ->
    res.json(hub.clientCount)

app.get '/info', (req, res, next) ->
    res.json(info)
