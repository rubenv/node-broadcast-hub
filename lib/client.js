var Client, after, redis,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

redis = require('redis');

after = require('./utils').after;

Client = (function() {
  function Client(hub, id, socket) {
    this.hub = hub;
    this.id = id;
    this.socket = socket;
    this.checkAuthenticated = __bind(this.checkAuthenticated, this);
    this.onDisconnect = __bind(this.onDisconnect, this);
    this.onSubscribe = __bind(this.onSubscribe, this);
    this.onConnect = __bind(this.onConnect, this);
    this.onMessage = __bind(this.onMessage, this);
    this.onData = __bind(this.onData, this);
    this.callback = __bind(this.callback, this);
    this.authenticated = false;
    this.redis = redis.createClient();
    this.redis.on('message', this.onMessage);
    this.socket.on('close', this.onDisconnect);
    this.socket.on('data', this.onData);
    after(10 * 1000, this.checkAuthenticated);
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
    if (obj.message === 'hubConnect') {
      return this.onConnect(obj.data, this.callback(obj._seq));
    } else if (obj.message === 'hubSubscribe') {
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

  Client.prototype.onConnect = function(data, cb) {
    var _this = this;
    return this.hub.canConnect(this, data, function(err, allowed) {
      if (err) {
        return cb(err);
      }
      if (!allowed) {
        return cb('handshake unauthorized');
      } else {
        _this.authenticated = true;
        return cb();
      }
    });
  };

  Client.prototype.onSubscribe = function(channel, cb) {
    var _this = this;
    if (!this.authenticated) {
      return cb('handshake required');
    }
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

  Client.prototype.checkAuthenticated = function() {
    if (!this.authenticated) {
      return this.disconnect();
    }
  };

  return Client;

})();

module.exports = Client;
