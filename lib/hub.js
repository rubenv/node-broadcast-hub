var BroadcastHub, Client, redis, socketIo,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

redis = require('redis');

socketIo = require('socket.io');

Client = require('./client');

BroadcastHub = (function() {
  function BroadcastHub(server, options) {
    this.server = server;
    this.options = options != null ? options : {};
    this.onSocketConnect = __bind(this.onSocketConnect, this);
    this.clients = {};
    this.clientId = 0;
    this.io = socketIo.listen(this.server, {
      'log level': 1
    });
    this.io.set('authorization', this.options.canConnect || false);
    this.io.sockets.on('connection', this.onSocketConnect);
  }

  BroadcastHub.prototype.onSocketConnect = function(socket) {
    this.clients[this.clientId] = new Client(this, this.clientId, socket);
    return this.clientId += 1;
  };

  BroadcastHub.prototype.disconnect = function(client) {
    return delete this.clients[client.id];
  };

  BroadcastHub.prototype.disconnectAll = function() {
    var client, id, _ref;
    _ref = this.clients;
    for (id in _ref) {
      client = _ref[id];
      client.disconnect();
    }
    return this.clients = {};
  };

  BroadcastHub.prototype.canSubscribe = function(client, channel, cb) {
    if (!this.options.canSubscribe) {
      return cb(null, true);
    }
    return this.options.canSubscribe(client.socket.handshake, channel, cb);
  };

  BroadcastHub.prototype.publish = function(channel, message, cb) {
    if (!this.publishClient) {
      this.publishClient = redis.createClient();
    }
    return this.publishClient.publish(channel, message, cb);
  };

  Object.defineProperty(BroadcastHub.prototype, 'clientCount', {
    get: function() {
      var clients, key;
      clients = 0;
      for (key in this.clients) {
        clients += 1;
      }
      return clients;
    }
  });

  return BroadcastHub;

})();

module.exports = BroadcastHub;
