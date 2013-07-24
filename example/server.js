var express = require('express');
var broadcastHub = require('..');

var app = express();
var server = require('http').createServer(app);
broadcastHub.listen(server);

app.get('/', function (req, res) {
    res.sendfile(__dirname + '/client.html');
});

app.listen(3000);
console.log('Listening on http://localhost:3000/');
