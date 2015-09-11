cozydb  = require 'cozydb'
request = require 'request'
crypto  = require 'crypto'
printit = require 'printit'

log = printit
	prefix: 'models:twitterAccount'
	date: true

params =
	"oauth_next": "oob"
	"oauth_consumer_key": "4IeD033v2gU0BozKfVVoMd6vZ"
	"oauth_version": "1.0"
	"oauth_signature_method": "HMAC-SHA1"
	"oauth_nonce": null
	"oauth_timestamp": null
	"oauth_token": null
	"oauth_verifier": null

module.exports = class twitterAccount extends cozydb.CozyModel
	@docType: 'twitterAccount'

	@schema:
		oauth_token: String     # OAuth token
		password: String        # OAuth secret token
		user_id: Number         # Twitter user ID
		screen_name: String     # Twitter username

	@tokens =
		temp: null
		final: null

	@getTempTokens: (next) =>
		header = @getSignedHeader "https://api.twitter.com/oauth/request_token", [
			"oauth_next"
			"oauth_consumer_key"
			"oauth_nonce"
			"oauth_signature_method"
			"oauth_timestamp"
			"oauth_version"
		]

		request.post
			url: "https://api.twitter.com/oauth/request_token"
			headers:
				"Authorization":header
		, (err, status, body) =>
			if err
				callback err
			else
				data = @bodyToJSON(body)
				next null, data
				#log.info "Got token "+data.oauth_token
				@tokens.temp = data.oauth_token

	@getNonce: () ->
		text = "";
		possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

		i = 0
		while i isnt 32
			text += possible.charAt(Math.floor(Math.random() * possible.length))
			i++
		(new Buffer(text)).toString()

	@getParameters: (oauthParams, additionalInfo) =>
		parameters = []
		for key, value of params
			if oauthParams.indexOf(key) isnt -1
				finalValue = null
				switch key
					when "oauth_nonce" then finalValue = @getNonce()
					when "oauth_timestamp" then finalValue = Math.round(Date.now()/1000)
				if additionalInfo[key]
					finalValue = additionalInfo[key]
				if finalValue is null
					finalValue = value
				parameters.push encodeURIComponent(key)+"="+encodeURIComponent(finalValue)
		console.log parameters
		parameters = parameters.sort()



	@getSignedHeader: (url, oauthParams, additionalInfo) =>
		parameters = @getParameters(oauthParams, additionalInfo)

		signBase = parameters.join('&')
		signature = "POST"+"&"+encodeURIComponent(url)+"&"+encodeURIComponent(signBase)
		consumer_secret = "UIKd7zyEX8gAmcJFltz86oTpFjbLxiNWTutXgO9S3PjC7EV9DX"
		signing_key = encodeURIComponent(consumer_secret)+"&"
		signature = crypto.createHmac('sha1', signing_key).update(signature).digest('base64')

		header = 'OAuth '+parameters.join(', ')+', '+encodeURIComponent("oauth_signature")+'='+encodeURIComponent(signature)
		header

	@bodyToJSON: (body) ->
		elements = body.split '&'
		json = {}
		for element in elements
			[key, value] = element.split '='
			json[key] = value
		json

	@validatePIN: (pin, next) ->
		header = @getSignedHeader "https://api.twitter.com/oauth/access_token", [
			"oauth_consumer_key"
			"oauth_nonce"
			"oauth_signature_method"
			"oauth_timestamp"
			"oauth_version"
			"oauth_verifier"
			"oauth_token"
		], {"oauth_verifier": pin, "oauth_token": @tokens.temp}

		request.post
			url: "https://api.twitter.com/oauth/access_token"
			headers:
				"Authorization": header
		, (err, status, body) =>
				if err
					next err
				else
					if status.statusCode is 200
						data = @bodyToJSON(body)
						@create
							oauth_token: data.oauth_token
							password: data.oauth_token_secret
							user_id: data.user_id
							screen_name: data.screen_name
						, (err, result) ->
							log.info "Successfully logged in as "+data.screen_name
							next null, true
					else
						log.error "Can't log in, server responded with a "+status.statusCode+" status code. Full message:"
						console.error body
						next null, false

	@loadLastLogin: (next) ->
		@request 'all', (err, results) =>
			@tokens.final = results
			next()

	@whoAmI: ->
		console.log @tokens
		@tokens.final