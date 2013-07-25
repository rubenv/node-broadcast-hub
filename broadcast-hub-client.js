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
      var _this = this;
      this.options = options != null ? options : {};
      this._onDisconnected = __bind(this._onDisconnected, this);
      this._processMessage = __bind(this._processMessage, this);
      this._listeners = {};
      this.client = io.connect(options.server, {
        'force new connection': true
      });
      this.client.on('hubMessage', this._processMessage);
      this.client.on('hubSubscribed', function() {
        return _this.emit('connected');
      });
      this.client.on('disconnect', this._onDisconnected);
    }

    BroadcastHubClient.prototype.on = function(event, cb) {
      if (!this._listeners[event]) {
        this._listeners[event] = [];
      }
      return this._listeners[event].push(cb);
    };

    BroadcastHubClient.prototype.once = function(event, cb) {
      var wrapper;
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
      this.emit('message', message.channel, message.message);
      return this.emit("message:" + message.channel, message.message);
    };

    BroadcastHubClient.prototype._onDisconnected = function(reason) {
      this.emit('disconnected');
      if (reason !== 'booted') {
        return console.log(arguments);
      }
    };

    BroadcastHubClient.prototype.disconnect = function(cb) {
      if (cb) {
        this.client.once('disconnected', function() {
          console.log(arguments);
          return cb();
        });
      }
      return this.client.disconnect();
    };

    return BroadcastHubClient;

  })();

  if (typeof module !== 'undefined') {
    module.exports = BroadcastHubClient;
  } else {
    root.BroadcastHubClient = BroadcastHubClient;
  }

}).call(this);
