twitterAccount = require '../models/twitterAccount'

module.exports.token = (req, res) ->
	twitterAccount.getTempTokens (err, results) ->
		res.json results

module.exports.pin = (req, res) ->
	twitterAccount.validatePIN req.params.pin, (err, results) ->
		res.json results

module.exports.tweet = (req, res) ->
	twitterAccount.tweet req.body.tweet, (err, results) ->
		console.log err
		res.json results

module.exports.timeline = (req, res) ->
	twitterAccount.getTimeline "timeline", (err, timeline) ->
		if err
			console.log err
		else
			res.send timeline

module.exports.dm = (req, res) ->
	twitterAccount.getTimeline "direct_messages", (err, timeline) ->
		if err
			console.log err
		else
			res.send timeline

module.exports.streaming = (req, res) ->
	twitterAccount.getStreamingTimeline "timeline", (err, chunk) ->
		if err
			console.log err
		else
			json = JSON.parse chunk
			res.write chunk
			console.log chunk

module.exports.mentions = (req, res) ->
	twitterAccount.getTimeline "mentions", (err, chunk) ->
		if err
			console.log err
		else
			res.send timeline

module.exports.stream = (req, res) ->
	twitterAccount.getStreamingTimeline (chunk) ->
		res.write chunk
		Timer.setTimeout () ->
			res.end()
		, 5000

module.exports.getTweet = (req, res) ->
	twitterAccount.getTweet req.params.id, (err, result) ->
		res.json result

module.exports.action = (req, res) ->
	if req.body.action is "retweet"
		twitterAccount.retweet req.params.id, (err, tweet) ->
			res.send tweet
			if err
				console.log err
	else if req.body.action is "favorite"
		twitterAccount.favorite req.params.id, (err, tweet) ->
			if err
				console.log err
			else
				res.send tweet
	else
		res.status(404).json error: "Action undefined"

module.exports.delete = (req, res) ->
	twitterAccount.delete req.params.id, (err, stuff) ->
		if err
			console.log err
		else
			res.json stuff