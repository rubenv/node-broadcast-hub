# broadcast-hub - WebSockets backed by Redis pubsub.

> Exposes redis pubsub channels over websockets.

[![Build Status](https://travis-ci.org/rubenv/node-broadcast-hub.png?branch=master)](https://travis-ci.org/rubenv/node-broadcast-hub)

## Introduction

The broadcast-hub module provides easy-to-use middleware for adding real-time notifications to your web applications. It is intended to be both easy to integrate (low effort) yet scalable.

The hub consists of a number of broadcast channels to which clients can subscribe. Once subscribed, they'll receive any message posted to that channel.

What it does:

* Provide the needed Websocket handling (based on [sockjs](http://sockjs.org/)).
* Provides a client-side library for subscribing to broadcast channels.
* Uses [redis](http://redis.io/) as a pubsub mechanism to achieve scalability.
* Allows authenticating clients and individual channels.
* Automatic connection handling (including reconnecting on connection loss).

## Getting started
### Requirements
You'll need a redis server on the backend. Redis takes care of all the message routing, broadcast-hub simply publishes those messages over websockets.

### Server-side
Add broadcast-hub to your project (backend components):

```
npm install --save broadcast-hub
```

You'll need to setup a broadcast-hub on the server. This can be a standalone component or part of your existing Node.JS backend.

If you are using [Express](http://expressjs.com/):

```js
var express = require('express');
var broadcastHub = require('broadcast-hub');

var app = express();
// Do Express configuration
var server = app.listen(3000);      // (1)
broadcastHub.listen(server);        // (2)
```

1. When you call `app.listen`, the return value will be a `http.Server`, store this in a variable.
2. Pass the `http.Server` to broadcast-hub. This will set up the needed sockjs listeners.

A full example can be found in `example/server.js`.

### Client-side
Add broadcast-hub to your project (client-side components):

```
bower install --save broadcast-hub
```

Add the socketjs and broadcast-hub libraries to your app:

```html
<head>
    <!-- More stuff here -->
    <script src="bower_components/sockjs/sockjs.min.js"></script>
    <script src="bower_components/broadcast-hub/broadcast-hub-client.min.js"></script>
</head>
```

Then, in your client-side JavaScript, connect to the hub and subscribe to some channels:

```js
var client = new BroadcastHubClient();
client.subscribe('test');
client.on('message:test', function (message) {
	console.log(message);
})
```

All received messages in the `test` channel will be output to the console.

#### Client options
You can optionally pass an options object to the client:

```js
var client = new BroadcastHubClient({
    /* Options here */
});
```

##### `auth`
**Type:** `object`

Any data that should be passed to the `canConnect` function on the backend, as the `data` argument.

##### `server`
**Type:** `string`

The URL on which the client should connect.


### Publishing messages
Using any redis client, publish a message on the same channel and it'll get relayed to the clients.

For instance, using the `redis-cli` client:

```
$ redis-cli 
redis 127.0.0.1:6379> publish test "Test message"
```

This will result in `Test message` showing up in the browser console.

There are no special requirements for publishing messages, so you can use any redis client for publishing, such as [node-redis (Node.JS)](https://github.com/mranney/node_redis) or [predis (PHP)](https://github.com/nrk/predis). This is by design: it should be as trivial as possible to publish messages.

From Node.JS, use something like this:

```js
var redis = require('redis');
var client = redis.createClient();
client.publish('test', 'Test message');
```

There's also a convenience method defined on the hub object that's returned when calling `listen`:

```js
var hub = broadcastHub.listen(server);
hub.publish('test', 'Test message');
```

You can optionally pass a completion callback as the third argument to this function.

## Scalability
The architecture of broadcast-hub is deliberatly kept simple to make scaling possible.

PubSub is delegate to Redis. Node.JS makes one Redis connection per subscribed channel. This allows fast broadcasting among clients.

If you start to run into the limits of Node.JS:

* Add more Node.JS instances to which clients can connect.
* Use a load balancer to spread clients across these backends instances.
* There is no requirement for pinning clients to backend instances. Clients will automatically reconnect if one of the backends goes down and restore all subscriptions. This should be transparent.

If you start to run into the limits of redis:

* Use [master/slave replication](http://redis.io/topics/replication) to add more redis tiers.

Be sure to have sufficiently high connection limits set up. You'll need N+M TCP connections (where N is the number of connected clients and M is the number of subscribed channels in total [1]).

Add another TCP connection per client if you have nginx or haproxy as a reverse-proxy (not strictly needed, though recommended to offload compression and encryption).

[1] Two clients connecting to the same channel will only result in one connection to Redis.

## Configuration
You can pass an options object to the `listen` call:

```js
broadcastHub.listen(server, {
    /* Options here */
});
```

### `canConnect`
**Type:** `function (client, data, cb)`

A function that can be used to determine whether or not the connecting client is allowed to connect to the broadcast hub. The passed `data` object is supplied by the client and can be configured using the `auth` option on the client.

The result of this authorization check should be passed to the callback `cb`: This function takes two arguments: an error or a boolean value.

Example:

```js
broadcastHub.listen(server, {
	canConnect: function (client, data, cb) {
	    // Do some database lookups here
	    cb(null, true);
	}    
});
```

You can store data associated to a client in the `client.data` field.

Example:

```js
	canConnect: function (client, data, cb) {
	    // Look up client information
	    client.data.user = user;
	    cb(null, true);
	}    
```

This data will then be accessible in `canSubscribe`.


### `canSubscribe`
**Type:** `function (client, channel, cb)`

Similar to `canConnect`, except that this function decides whether or not the client can subscribe to the requested channel.

### `prefix`
**Type:** `string`

The URL path on which the socket handlers should be installed. Defaults to `/sockets`.

### `redisHost`
**Type:** `string` (default: `127.0.0.1`)

The hostname of the redis server used for subscriptions.

### `redisPort`
**Type:** `int` (default: `6379`)

The port of the redis server used for subscriptions.

### `publishHost`
**Type:** `string` (default: `options.redisHost`)

The hostname of the redis server used for publishing messages (may be different if you use master/server replication).

### `redisPort`
**Type:** `int` (default: `options.publishPort`)

The port of the redis server used for publishing.

## Contributing
All code lives in the `src` folder and is written in CoffeeScript. Try to stick to the style conventions used in existing code.

Tests can be run using `grunt test`. A convenience command to automatically run the tests is also available: `grunt watch`. Please add test cases when adding new functionality: this will prove that it works and ensure that it will keep working in the future.

    
## License 

    (The MIT License)

    Copyright (C) 2013 by Ruben Vermeersch <ruben@savanne.be>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
