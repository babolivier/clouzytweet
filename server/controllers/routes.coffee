# See documentation on https://github.com/frankrousseau/americano#routes

twitter = require './twitter'

module.exports =
    'twitter/tokens':
        get: twitter.token

    'twitter/pin/:pin':
        get: twitter.pin

    'user/tweet/':
        post: twitter.tweet

    'user/tweet/:id':
        get: twitter.getTweet
        post: twitter.retweet

    'user/timeline':
        get: twitter.timeline

    'user/stream':
        get: twitter.stream