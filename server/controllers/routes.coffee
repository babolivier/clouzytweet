# See documentation on https://github.com/frankrousseau/americano#routes

twitter = require './twitter'

module.exports =
    'twitter/tokens':
        get: twitter.token

    'twitter/pin/:pin':
        get: twitter.pin

    'twitter/load':
        get:twitter.load