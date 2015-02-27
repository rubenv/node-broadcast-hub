var BroadcastHub, Client, defaults, redis, sockjs,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

redis = require('redis');

sockjs = require('sockjs');

defaults = require('./utils').defaults;

Client = require('./client');

BroadcastHub = (function() {
  function BroadcastHub(server, options) {
    this.server = server;
    this.options = options != null ? options : {};
    this.onSocketConnect = __bind(this.onSocketConnect, this);
    this.clients = {};
    this.clientId = 0;
    defaults(this.options, {
      redisHost: '127.0.0.1',
      redisPort: 6379,
      publishHost: this.options.redisHost || '127.0.0.1',
      publishPort: this.options.redisPort || 6379
    });
    this.channels = {};
    this.socket = sockjs.createServer({
      log: this.options.log || function() {}
    });
    this.socket.installHandlers(this.server, {
      prefix: this.options.prefix || '/sockets'
    });
    this.socket.on('connection', this.onSocketConnect);
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

  BroadcastHub.prototype.canConnect = function(client, data, cb) {
    if (!this.options.canConnect) {
      return cb(null, true);
    }
    return this.options.canConnect(client, data, cb);
  };

  BroadcastHub.prototype.canSubscribe = function(client, channel, cb) {
    if (!this.options.canSubscribe) {
      return cb(null, true);
    }
    return this.options.canSubscribe(client, channel, cb);
  };

  BroadcastHub.prototype.publish = function(channel, message, cb) {
    if (!this.publishClient) {
      this.publishClient = redis.createClient(this.options.publishPort, this.options.publishHost);
      if (this.options.publishAuth) {
        this.publishClient.auth(this.options.publishAuth);
      }
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
