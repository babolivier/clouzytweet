twitterAccount = require '../models/twitterAccount'

module.exports.token = (req, res, next) ->
	twitterAccount.getTempTokens (err, results) ->
		res.json results

module.exports.pin = (req, res, next) ->
	twitterAccount.validatePIN req.params.pin, (err, results) ->
		res.json results

module.exports.tweet = (req, res, next) ->
	twitterAccount.tweet req.body.tweet, (err, results) ->
		console.log err
		res.json results

module.exports.timeline = (req, res, next) ->
	data = []
	res.write '<meta charset="utf-8">Tweets in the last minute:<br>'
	setTimeout () ->
		for tweet in data
			res.write tweet+'<br>'
		res.end()
	, 60000

	twitterAccount.getStreamingTimeline (err, chunk) ->
		if err
			console.log err
		else
			json = JSON.parse chunk
			if json.created_at
				data.push json.text+' sent by @'+json.user.screen_name
			console.log chunk

module.exports.stream = (req, res, next) ->
	twitterAccount.getStreamingTimeline (chunk) ->
		res.write chunk
		Timer.setTimeout () ->
			res.end()
		, 5000

module.exports.getTweet = (req, res, next) ->
	res.send "Hello world"

module.exports.retweet = (req, res, next) ->
	res.send "Hello world"