twitterAccount = require '../models/twitterAccount'

module.exports.token = (req, res, next) ->
	twitterAccount.getTempTokens (err, results) ->
		res.json results

module.exports.pin = (req, res, next) ->
	twitterAccount.validatePIN req.params.pin, (err, results) ->
		res.json results

module.exports.load = (req, res, next) ->
	twitterAccount.loadLastLogin () ->
		res.json twitterAccount.whoAmI()

module.exports.tweet = (req, res, next) ->
	twitterAccount.tweet req.params.tweet, (err, results) ->
		res.json results