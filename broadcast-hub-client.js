(function() {
  var BroadcastHubClient, SockJS, root,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

  root = this;

  SockJS = root.SockJS;

  if (!SockJS) {
    throw Error('No SockJS found, be sure to include it!');
  }

  BroadcastHubClient = (function() {
    function BroadcastHubClient(options) {
      this.options = options != null ? options : {};
      this._onError = __bind(this._onError, this);
      this._onDisconnected = __bind(this._onDisconnected, this);
      this._onConnected = __bind(this._onConnected, this);
      this._processMessage = __bind(this._processMessage, this);
      this._listeners = {};
      this._channels = [];
      this._queue = [];
      this._connected = false;
      this._seq = 0;
      this.connect();
    }

    BroadcastHubClient.prototype.connect = function() {
      this.client = new SockJS(this.options.server || "/sockets");
      this.client.onopen = this._onConnected;
      this.client.onclose = this._onDisconnected;
      return this.client.onmessage = this._processMessage;
      /*
      @client.on 'hubMessage', @_processMessage
      @client.on 'disconnect', @_onDisconnected
      @client.on 'error', @_onError
      
      @client.on 'connect', () =>
          # Resubscribe any previously-open channels
          @subscribe(channel) for channel in @_channels
      */

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
      var data;
      data = JSON.parse(message.data);
      if (data.type === 'callback') {
        return this.emit("_callback:" + data.seq, data.err, data.data);
      } else {
        this.emit("message:" + data.channel, data.message);
        return this.emit('message', data.channel, data.message);
      }
    };

    BroadcastHubClient.prototype._onConnected = function() {
      var msg, _i, _len, _ref;
      this._connected = true;
      _ref = this._queue;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        msg = _ref[_i];
        this.client.send(JSON.stringify(msg));
      }
      return this._queue = [];
    };

    BroadcastHubClient.prototype._onDisconnected = function() {
      return this.emit('disconnected');
    };

    BroadcastHubClient.prototype._onError = function(err) {
      return this.emit('error', err);
    };

    BroadcastHubClient.prototype.disconnect = function(cb) {
      var _this = this;
      this.once('disconnected', cb);
      return this.send({
        message: 'disconnect'
      }, function() {
        return _this.client.close();
      });
    };

    BroadcastHubClient.prototype.send = function(data, cb) {
      if (data == null) {
        data = {};
      }
      if (cb) {
        data._seq = this._seq++;
        this.once("_callback:" + data._seq, cb);
      }
      if (!this._connected) {
        this._queue.push(data);
      } else {
        this.client.send(JSON.stringify(data));
      }
      return data._seq;
    };

    BroadcastHubClient.prototype.subscribe = function(channel, cb) {
      var _this = this;
      return this.send({
        message: 'hubSubscribe',
        channel: channel
      }, function(err) {
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
