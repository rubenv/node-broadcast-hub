redis = require 'redis'
redisClient = redis.createClient()
express = require 'express'
broadcastHub = require '../..'

http = null
server = null
hub = null

app = express()
app.use(express.json())

stopServer = (cb) ->
    return cb() if !http
    http.close(cb)
    http = null

app.post '/start', (req, res, next) ->
    stopServer (err) ->
        return next(err) if err
        server = express()
        http = server.listen(9875)
        hub = broadcastHub.listen(http, {
            log: (level, msg) ->
                if /SockJS v.\..\.. bound to/.test(msg)
                    res.json 'OK'
                #console.log "#{level}: #{msg}"
        })

app.post '/sendMessage', (req, res, next) ->
    redisClient.publish req.body.channel, req.body.message, () ->
        res.json 'OK'

app.post '/stop', (req, res, next) ->
    http.close() if http
    http = null
    res.json 'OK'

app.post '/clients', (req, res, next) ->
    res.json(hub.clientCount)

console.log '## Starting test coordinator'
app.listen(9876)
