var path = require('path');
var express = require('express');
var broadcastHub = require('..'); // Use require('broadcast-hub') in your project.

// Create the express app (or skip this if you don't use express)
var app = express();

// Sets up the example app, serves files from the project root
app.use(express.static(path.join(__dirname, '..')));

// Start the express app
var server = app.listen(3000);

// Pass the http server to broadcastHub
broadcastHub.listen(server);

console.log('Listening on http://localhost:3000/example/');
