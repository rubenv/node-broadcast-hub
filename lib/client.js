var Channel, Client, after,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

after = require('./utils').after;

Channel = require('./channel');

Client = (function() {
  function Client(hub, id, socket) {
    this.hub = hub;
    this.id = id;
    this.socket = socket;
    this.checkAuthenticated = __bind(this.checkAuthenticated, this);
    this.onDisconnect = __bind(this.onDisconnect, this);
    this.onSubscribe = __bind(this.onSubscribe, this);
    this.onConnect = __bind(this.onConnect, this);
    this.relay = __bind(this.relay, this);
    this.onData = __bind(this.onData, this);
    this.callback = __bind(this.callback, this);
    this.authenticated = false;
    this.channels = [];
    this.data = {};
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

  Client.prototype.relay = function(channel, message) {
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

  Client.prototype.onSubscribe = function(name, cb) {
    var _this = this;
    if (!this.authenticated) {
      return cb('handshake required');
    }
    return this.hub.canSubscribe(this, name, function(err, allowed) {
      if (err) {
        return cb(err);
      }
      if (!allowed) {
        return cb('subscription refused');
      }
      return Channel.get(name, function(err, channel) {
        if (err) {
          return cb(err);
        }
        channel.subscribe(_this);
        _this.channels.push(channel);
        return cb();
      });
    });
  };

  Client.prototype.disconnect = function() {
    this.onDisconnect();
    return this.socket.close();
  };

  Client.prototype.onDisconnect = function() {
    var channel, _i, _len, _ref;
    if (this.hub) {
      this.hub.disconnect(this);
    }
    this.hub = null;
    _ref = this.channels;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      channel = _ref[_i];
      channel.unsubscribe(this);
    }
    return this.channels = null;
  };

  Client.prototype.checkAuthenticated = function() {
    if (!this.authenticated) {
      return this.disconnect();
    }
  };

  return Client;

})();

module.exports = Client;
