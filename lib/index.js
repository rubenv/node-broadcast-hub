var BroadcastHub;

BroadcastHub = require('./hub');

module.exports = {
  listen: function(server) {
    return new BroadcastHub(server);
  }
};
