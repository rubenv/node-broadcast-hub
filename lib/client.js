var Client, redis,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

redis = require('redis');

Client = (function() {
  function Client(hub, id, socket) {
    var _this = this;
    this.hub = hub;
    this.id = id;
    this.socket = socket;
    this.onDisconnect = __bind(this.onDisconnect, this);
    this.onPMessage = __bind(this.onPMessage, this);
    this.redis = redis.createClient();
    this.redis.on('pmessage', this.onPMessage);
    this.redis.psubscribe('*', function(err) {
      return _this.socket.emit('hubSubscribed');
    });
    this.socket.on('disconnect', this.onDisconnect);
  }

  Client.prototype.onPMessage = function(pattern, channel, message) {
    return this.socket.emit('hubMessage', {
      channel: channel,
      message: message
    });
  };

  Client.prototype.onDisconnect = function() {
    this.hub.disconnect(this);
    return this.redis.quit();
  };

  return Client;

})();

module.exports = Client;
