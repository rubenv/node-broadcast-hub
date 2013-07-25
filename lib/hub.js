var BroadcastHub, Client, socketIo,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

socketIo = require('socket.io');

Client = require('./client');

BroadcastHub = (function() {
  function BroadcastHub(server) {
    this.server = server;
    this.onSocketConnect = __bind(this.onSocketConnect, this);
    this.clients = {};
    this.clientId = 0;
    this.io = socketIo.listen(this.server, {
      'log level': 1
    });
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
