(function() {
  var BroadcastHubClient, io, root,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

  root = this;

  io = root.io;

  if (!io && typeof require !== 'undefined') {
    io = require('socket.io-client');
  }

  if (!io) {
    throw Error('No Socket.IO found, be sure to include it!');
  }

  BroadcastHubClient = (function() {
    function BroadcastHubClient(options) {
      this.options = options != null ? options : {};
      this._onError = __bind(this._onError, this);
      this._onDisconnected = __bind(this._onDisconnected, this);
      this._processMessage = __bind(this._processMessage, this);
      this._listeners = {};
      this._channels = [];
      this.connect();
    }

    BroadcastHubClient.prototype.connect = function() {
      var _this = this;
      this.client = io.connect(this.options.server, {
        'force new connection': true
      });
      this.client.on('hubMessage', this._processMessage);
      this.client.on('disconnect', this._onDisconnected);
      this.client.on('error', this._onError);
      return this.client.on('connect', function() {
        var channel, _i, _len, _ref, _results;
        _ref = _this._channels;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          channel = _ref[_i];
          _results.push(_this.subscribe(channel));
        }
        return _results;
      });
    };

    BroadcastHubClient.prototype.on = function(event, cb) {
      if (!cb) {
        return;
      }
      if (!this._listeners[event]) {
        this._listeners[event] = [];
      }
      return this._listeners[event].push(cb);
    };

    BroadcastHubClient.prototype.once = function(event, cb) {
      var wrapper;
      if (!cb) {
        return;
      }
      wrapper = function() {
        cb.apply(this, arguments);
        return this.off(event, wrapper);
      };
      return this.on(event, wrapper);
    };

    BroadcastHubClient.prototype.off = function(event, cb) {
      if (!this._listeners[event] || __indexOf.call(this._listeners[event], cb) < 0) {
        return;
      }
      return this._listeners[event].splice(this._listeners[event].indexOf(cb), 1);
    };

    BroadcastHubClient.prototype.emit = function() {
      var args, event, listener, _i, _len, _ref, _results;
      event = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (!this._listeners[event]) {
        return;
      }
      _ref = this._listeners[event];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        listener = _ref[_i];
        _results.push(listener.apply(this, args));
      }
      return _results;
    };

    BroadcastHubClient.prototype._processMessage = function(message) {
      this.emit("message:" + message.channel, message.message);
      return this.emit('message', message.channel, message.message);
    };

    BroadcastHubClient.prototype._onDisconnected = function(reason) {
      return this.emit('disconnected');
    };

    BroadcastHubClient.prototype._onError = function(err) {
      return this.emit('error', err);
    };

    BroadcastHubClient.prototype.disconnect = function(cb) {
      this.once('disconnected', cb);
      return this.client.disconnect();
    };

    BroadcastHubClient.prototype.subscribe = function(channel, cb) {
      var _this = this;
      return this.client.emit('hubSubscribe', channel, function(err) {
        if (err) {
          if (cb) {
            cb(err);
          }
          return;
        }
        if (__indexOf.call(_this._channels, channel) < 0) {
          _this._channels.push(channel);
        }
        if (cb) {
          return cb();
        }
      });
    };

    return BroadcastHubClient;

  })();

  if (typeof module !== 'undefined') {
    module.exports = BroadcastHubClient;
  } else {
    root.BroadcastHubClient = BroadcastHubClient;
  }

}).call(this);
