module.exports = {
  after: function(timeout, cb) {
    return setTimeout(cb, timeout);
  },
  defaults: function(obj, defaults) {
    var key, val;
    for (key in defaults) {
      val = defaults[key];
      if (obj[key] == null) {
        obj[key] = val;
      }
    }
    return obj;
  }
};
