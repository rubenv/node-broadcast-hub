var Client, redis,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

redis = require('redis');

Client = (function() {
  function Client(hub, id, socket) {
    this.hub = hub;
    this.id = id;
    this.socket = socket;
    this.onDisconnect = __bind(this.onDisconnect, this);
    this.onSubscribe = __bind(this.onSubscribe, this);
    this.onMessage = __bind(this.onMessage, this);
    this.onData = __bind(this.onData, this);
    this.callback = __bind(this.callback, this);
    this.redis = redis.createClient();
    this.redis.on('message', this.onMessage);
    this.socket.on('close', this.onDisconnect);
    this.socket.on('data', this.onData);
  }

  Client.prototype.callback = function(id) {
    var _this = this;
    return function(err, data) {
      return _this.socket.write(JSON.stringify({
        type: 'callback',
        seq: id,
        err: err,
        data: data
      }));
    };
  };

  Client.prototype.onData = function(data) {
    var obj;
    obj = JSON.parse(data);
    if (obj.message === 'hubSubscribe') {
      return this.onSubscribe(obj.channel, this.callback(obj._seq));
    } else if (obj.message === 'disconnect') {
      return this.disconnect();
    }
  };

  Client.prototype.onMessage = function(channel, message) {
    return this.socket.write(JSON.stringify({
      type: 'message',
      channel: channel,
      message: message
    }));
  };

  Client.prototype.onSubscribe = function(channel, cb) {
    var _this = this;
    return this.hub.canSubscribe(this, channel, function(err, allowed) {
      if (err) {
        return cb(err);
      }
      if (!allowed) {
        return cb('subscription refused');
      }
      return _this.redis.subscribe(channel, function(err) {
        if (!cb) {
          return;
        }
        return cb(err, channel);
      });
    });
  };

  Client.prototype.disconnect = function() {
    this.onDisconnect();
    return this.socket.close();
  };

  Client.prototype.onDisconnect = function() {
    if (this.hub) {
      this.hub.disconnect(this);
    }
    if (this.redis) {
      this.redis.quit();
    }
    this.hub = null;
    return this.redis = null;
  };

  return Client;

})();

module.exports = Client;
