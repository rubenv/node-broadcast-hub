(function() {
  var BroadcastHubClient, SockJS, after, noop, root,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

  noop = function() {};

  after = function(timeout, cb) {
    return setTimeout(cb, timeout);
  };

  root = this;

  SockJS = root.SockJS;

  if (!SockJS) {
    throw Error('No SockJS found, be sure to include it!');
  }

  BroadcastHubClient = (function() {
    function BroadcastHubClient(options) {
      this.options = options != null ? options : {};
      this._onDisconnected = __bind(this._onDisconnected, this);
      this._onConnected = __bind(this._onConnected, this);
      this._processMessage = __bind(this._processMessage, this);
      this.connect = __bind(this.connect, this);
      this._listeners = {};
      this._channels = [];
      this._queue = [];
      this._connected = false;
      this._attempt = 0;
      this._seq = 0;
      this.connect();
    }

    BroadcastHubClient.prototype.connect = function() {
      this._shuttingDown = false;
      this._attempt = Math.min(this._attempt + 1, 20);
      if (this.client) {
        throw new Error("Already have a client!");
      }
      this.client = new SockJS(this.options.server || "/sockets");
      this.client.onopen = this._onConnected;
      this.client.onclose = this._onDisconnected;
      return this.client.onmessage = this._processMessage;
    };


    /*
     * Event emitter methods
     */

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
      wrapper = (function(_this) {
        return function() {
          cb.apply(_this, arguments);
          return _this.off(event, wrapper);
        };
      })(this);
      return this.on(event, wrapper);
    };

    BroadcastHubClient.prototype.off = function(event, cb) {
      if (!this._listeners[event] || __indexOf.call(this._listeners[event], cb) < 0) {
        return;
      }
      return this._listeners[event].splice(this._listeners[event].indexOf(cb), 1);
    };

    BroadcastHubClient.prototype.emit = function() {
      var args, event, listener, listeners, _i, _len;
      event = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (!this._listeners[event]) {
        return;
      }
      listeners = this._listeners[event].slice(0);
      for (_i = 0, _len = listeners.length; _i < _len; _i++) {
        listener = listeners[_i];
        listener.apply(this, args);
      }
    };


    /*
     * Internal methods
     */

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

    BroadcastHubClient.prototype._handshake = function(cb) {
      return this.send({
        message: 'hubConnect',
        data: this.options.auth || {}
      }, cb);
    };

    BroadcastHubClient.prototype._onConnected = function() {
      this._attempt = 0;
      this._connected = true;
      return this._handshake((function(_this) {
        return function(err) {
          var channel, emitConnected, msg, toSubscribe, _i, _j, _len, _len1, _ref, _ref1;
          if (err) {
            return _this.emit('error', err);
          }
          _ref = _this._queue;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            msg = _ref[_i];
            _this.client.send(msg);
          }
          _this._queue = [];
          emitConnected = function() {
            if (toSubscribe === 0) {
              return _this.emit('connected');
            }
          };
          toSubscribe = _this._channels.length;
          _ref1 = _this._channels;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            channel = _ref1[_j];
            _this.subscribe(channel, function(err) {
              toSubscribe -= 1;
              return emitConnected();
            });
          }
          return emitConnected();
        };
      })(this));
    };

    BroadcastHubClient.prototype._onDisconnected = function() {
      this.client.onopen = null;
      this.client.onclose = null;
      this.client.onmessage = null;
      this.client = null;
      this._connected = false;
      this.emit('disconnected');
      if (!this._shuttingDown) {
        return after(this._attempt * 250, this.connect);
      }
    };


    /*
     * External API
     */

    BroadcastHubClient.prototype.disconnect = function(cb) {
      if (cb == null) {
        cb = noop;
      }
      this._shuttingDown = true;
      if (!this._connected) {
        return cb();
      }
      this.once('disconnected', cb);
      return this.send({
        message: 'disconnect'
      }, (function(_this) {
        return function() {
          return _this.client.close();
        };
      })(this));
    };


    /*
        Send some data back to the server.
    
        Optionally accepts a callback function. When supplied, an extra _seq
        field will be sent to the server, this can then be used server-side to
        reply to the message. Typical use-case is returning the result of
        authenticate / subscribe.
     */

    BroadcastHubClient.prototype.send = function(data, cb) {
      var payload;
      if (data == null) {
        data = {};
      }
      if (cb) {
        data._seq = this._seq++;
        this.once("_callback:" + data._seq, cb);
      }
      payload = JSON.stringify(data);
      if (!this._connected) {
        this._queue.push(payload);
      } else {
        this.client.send(payload);
      }
      return data._seq;
    };

    BroadcastHubClient.prototype.subscribe = function(channel, cb) {
      if (cb == null) {
        cb = noop;
      }
      return this.send({
        message: 'hubSubscribe',
        channel: channel
      }, (function(_this) {
        return function(err) {
          if (err) {
            _this.emit('error', err);
            cb(err);
            return;
          }
          if (__indexOf.call(_this._channels, channel) < 0) {
            _this._channels.push(channel);
          }
          return cb();
        };
      })(this));
    };

    return BroadcastHubClient;

  })();

  root.BroadcastHubClient = BroadcastHubClient;

}).call(this);
