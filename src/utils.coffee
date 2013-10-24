module.exports =
    after: (timeout, cb) -> setTimeout(cb, timeout)

    defaults: (obj, defaults) ->
        for key, val of defaults
            obj[key] ?= val
        return obj
