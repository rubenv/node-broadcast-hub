var Channel, channels, redis,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

redis = require('redis');

channels = {};

Channel = (function() {
  Channel.get = function(name, cb) {
    var channel;
    if (channels[name]) {
      return cb(null, channels[name]);
    }
    channel = channels[name] = new Channel(name);
    return channel.prepare(function(err) {
      return cb(err, channel);
    });
  };

  function Channel(name) {
    this.name = name;
    this.onMessage = __bind(this.onMessage, this);
    this.clients = [];
    this.redis = redis.createClient();
    this.redis.on('message', this.onMessage);
  }

  Channel.prototype.prepare = function(cb) {
    return this.redis.subscribe(this.name, cb);
  };

  Channel.prototype.subscribe = function(client) {
    return this.clients.push(client);
  };

  Channel.prototype.unsubscribe = function(client) {
    var index;
    index = this.clients.indexOf(client);
    if (index < 0) {
      return;
    }
    this.clients.splice(index, 1);
    if (this.clients.length === 0) {
      this.redis.unsubscribe(this.name);
      this.redis.quit();
      delete channels[this.name];
    }
  };

  Channel.prototype.onMessage = function(channel, message) {
    var client, _i, _len, _ref;
    _ref = this.clients;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      client = _ref[_i];
      client.relay(channel, message);
    }
  };

  return Channel;

})();

module.exports = Channel;
