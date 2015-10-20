// Generated by CoffeeScript 1.9.3
var twitterAccount;

twitterAccount = require('../models/twitterAccount');

module.exports.token = function(req, res) {
  return twitterAccount.getTempTokens(function(err, results) {
    return res.json(results);
  });
};

module.exports.pin = function(req, res) {
  return twitterAccount.validatePIN(req.params.pin, function(err, results) {
    return res.json(results);
  });
};

module.exports.tweet = function(req, res) {
  return twitterAccount.tweet(req.body.tweet, function(err, results) {
    console.log(err);
    return res.json(results);
  });
};

module.exports.timeline = function(req, res) {
  return twitterAccount.getTimeline("timeline", function(err, timeline) {
    if (err) {
      return console.log(err);
    } else {
      return res.send(timeline);
    }
  });
};

module.exports.dm = function(req, res) {
  return twitterAccount.getTimeline("direct_messages", function(err, timeline) {
    if (err) {
      return console.log(err);
    } else {
      return res.send(timeline);
    }
  });
};

module.exports.streaming = function(req, res) {
  return twitterAccount.getStreamingTimeline("timeline", function(err, chunk) {
    var json;
    if (err) {
      return console.log(err);
    } else {
      json = JSON.parse(chunk);
      res.write(chunk);
      return console.log(chunk);
    }
  });
};

module.exports.mentions = function(req, res) {
  return twitterAccount.getTimeline("mentions", function(err, timeline) {
    if (err) {
      return console.log(err);
    } else {
      return res.send(timeline);
    }
  });
};

module.exports.stream = function(req, res) {
  return twitterAccount.getStreamingTimeline(function(chunk) {
    res.write(chunk);
    return Timer.setTimeout(function() {
      return res.end();
    }, 5000);
  });
};

module.exports.getTweet = function(req, res) {
  return twitterAccount.getTweet(req.params.id, function(err, result) {
    return res.json(result);
  });
};

module.exports.action = function(req, res) {
  if (req.body.action === "retweet") {
    return twitterAccount.retweet(req.params.id, function(err, tweet) {
      res.send(tweet);
      if (err) {
        return console.log(err);
      }
    });
  } else if (req.body.action === "favorite") {
    return twitterAccount.favorite(req.params.id, function(err, tweet) {
      if (err) {
        return console.log(err);
      } else {
        return res.send(tweet);
      }
    });
  } else {
    return res.status(404).json({
      error: "Action undefined"
    });
  }
};

module.exports["delete"] = function(req, res) {
  return twitterAccount["delete"](req.params.id, function(err, stuff) {
    if (err) {
      return console.log(err);
    } else {
      return res.json(stuff);
    }
  });
};