module.exports = {
  after: function(timeout, cb) {
    return setTimeout(cb, timeout);
  }
};
