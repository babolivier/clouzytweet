# See documentation on https://github.com/frankrousseau/americano#routes

twitter = require './twitter'

module.exports =
    'twitter/tokens':
        get: twitter.token

    'twitter/pin/:pin':
        get: twitter.pin

    'user/tweet/:tweet':
        get: twitter.tweet

    'user/timeline':
        get: twitter.timeline