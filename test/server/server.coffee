spawn = require('child_process').spawn

fs = require 'fs'
redis = require 'redis'
autoquit = require 'autoquit'
express = require 'express'
superagent = require 'superagent'

redisClient = redis.createClient()

pid = __dirname + '/hub.pid'

app = express()
app.use(express.json())

stopServer = () ->
    if fs.existsSync(pid)
        try
            process.kill(fs.readFileSync(pid, 'utf8'))
        fs.unlinkSync(pid)

app.post '/start', (req, res, next) ->
    stopServer()

    server = spawn 'coffee', [__dirname + '/hub.coffee'], { stdio: ['ignore', 'pipe', 'pipe' ] }
    server.stdout.on 'data', (data) ->
        if /SockJS v.\..+\..+ bound to/.test(data.toString())
            res.json 'OK'
        #console.log data.toString()
    server.stderr.on 'data', (data) ->
        console.error data.toString()
    fs.writeFileSync(pid, server.pid)

app.post '/sendMessage', (req, res, next) ->
    redisClient.publish req.body.channel, req.body.message, () ->
        res.json 'OK'

app.post '/stop', (req, res, next) ->
    stopServer()
    res.json 'OK'

app.post '/clients', (req, res, next) ->
    superagent
        .get("http://localhost:9875/clients")
        .end (result) ->
            res.json(result.body)

console.log '## Starting test coordinator'
http = app.listen(9876)
http.autoQuit()
