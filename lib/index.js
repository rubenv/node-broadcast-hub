var BroadcastHub;

BroadcastHub = require('./hub');

module.exports = {
  listen: function(server, options) {
    return new BroadcastHub(server, options);
  }
};
