var BroadcastHub, redis, socketIo,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

socketIo = require('socket.io');

redis = require('redis');

BroadcastHub = (function() {
  function BroadcastHub(server, cb) {
    this.server = server;
    this.onPMessage = __bind(this.onPMessage, this);
    this.onSocketConnect = __bind(this.onSocketConnect, this);
    this.connections = [];
    this.io = socketIo.listen(this.server, {
      'log level': 1
    });
    this.io.sockets.on('connection', this.onSocketConnect);
    this.redis = redis.createClient();
    this.redis.on('pmessage', this.onPMessage);
    this.redis.psubscribe('*', cb);
  }

  BroadcastHub.prototype.onSocketConnect = function(socket) {
    return this.connections.push(socket);
  };

  BroadcastHub.prototype.onPMessage = function(pattern, channel, message) {
    var connection, _i, _len, _ref, _results;
    _ref = this.connections;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      connection = _ref[_i];
      _results.push(connection.emit('event', {
        channel: channel,
        message: message
      }));
    }
    return _results;
  };

  return BroadcastHub;

})();

module.exports = {
  listen: function(server, cb) {
    return new BroadcastHub(server, cb);
  }
};
