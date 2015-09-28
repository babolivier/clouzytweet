cozydb  = require 'cozydb'
https   = require 'https'
modurl  = require 'url'
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
					when "oauth_timestamp" then finalValue = Math.floor(Date.now()/1000)
				if additionalInfo and additionalInfo[key]
						finalValue = additionalInfo[key]
				if finalValue is null
					finalValue = value
				parameters.push encodeURIComponent(key)+"="+encodeURIComponent(finalValue)
		parameters = parameters.sort()


	@getSignedHeader: (method, url, oauthParams, additionalInfo) =>
		parameters = @getParameters(oauthParams, additionalInfo)

		for field, info of additionalInfo
			if not field.match /^oauth/ # OAuth parameters are already in the array
				parameters.push encodeURIComponent(field)+"="+encodeURIComponent(info)

		parameters = parameters.sort()
		signBase = parameters.join('&')
		signature = method+"&"+encodeURIComponent(url)+"&"+encodeURIComponent(signBase)
		consumer_secret = "UIKd7zyEX8gAmcJFltz86oTpFjbLxiNWTutXgO9S3PjC7EV9DX"
		signing_key = encodeURIComponent(consumer_secret)+"&"
		if @tokens.final
			signing_key += encodeURIComponent(@tokens.final.password)
		signature = crypto.createHmac('sha1', signing_key).update(signature).digest('base64')

		parameters.push encodeURIComponent("oauth_signature")+'='+encodeURIComponent(signature)
		parameters.sort()

		header = 'OAuth '+parameters.join(', ')


	@sendSignedRequest: (method, url, oauthParams, additionalInfo, next) ->
		url = modurl.parse url

		oauthUrl = url.protocol+"//"+url.hostname+url.pathname
		header = @getSignedHeader method, oauthUrl, oauthParams, additionalInfo

		data = []
		for key, param of additionalInfo
			if not key.match /^oauth/
				data.push encodeURIComponent(key)+'='+encodeURIComponent(param)

		data = data.join("&")

		options =
			hostname: url.host
			port: 443
			path: url.path
			method: method
			headers:
				'Authorization': header

		if data
			if method is "GET"
				options["path"] = options["path"]+"?"+data
			else
				options["body"] = data

		req = https.request options, (res) =>
				if res.statusCode is 200
					next null, res
				else
					res.on "data", (data) ->
						err = new Error "Can't proceed the request, Twitter responded with a "+res.statusCode+\
						" status code. Full message: "+data
						log.error err
						next err

		req.on "error", (err) ->
			log.error "The server encountered a network error:"
			console.log err
			next err

		req.end()


	@bodyToJSON: (body) ->
		elements = body.split '&'
		json = {}
		for element in elements
			[key, value] = element.split '='
			json[key] = value
		json


	@saveUser: (data, next) ->
		@create
			oauth_token: data.oauth_token
			password: data.oauth_token_secret
			user_id: data.user_id
			screen_name: data.screen_name
		, (err, result) ->
			if err
				next err, null
			else
				log.info "Successfully logged in as "+data.screen_name+"."
				next null, true


	@loadLastLogin: (next) ->
		@request 'all', (err, results) =>
			if err
				next err
			else
				@tokens.final = results[0]
				log.info "Loaded user "+@tokens.final.screen_name+"."
				next null


	@getTempTokens: (next) =>
		@sendSignedRequest "POST", "https://api.twitter.com/oauth/request_token", [
			"oauth_callback"
			"oauth_consumer_key"
			"oauth_nonce"
			"oauth_signature_method"
			"oauth_timestamp"
			"oauth_version"
		], null, (err, res) =>
			if err
				next err
			else
				body = ""
				res.on "data", (chunk) ->
					body += chunk.toString()
				res.on "end", () =>
					data = @bodyToJSON(body)
					next null, data
					@tokens.temp = data.oauth_token


	@validatePIN: (pin, next) ->
		@sendSignedRequest "POST", "https://api.twitter.com/oauth/access_token", [
			"oauth_consumer_key"
			"oauth_nonce"
			"oauth_signature_method"
			"oauth_timestamp"
			"oauth_version"
			"oauth_verifier"
			"oauth_token"
		], {"oauth_verifier": pin, "oauth_token": @tokens.temp}, (err, res) =>
			body = ""
			res.on "data", (chunk) ->
				body += chunk.toString()
			res.on "end", () =>
				@saveUser @bodyToJSON(body), (err, created) ->
					next err, created


	@whoAmI: ->
		@tokens.final


	@tweet: (content, next) ->
		@loadLastLogin (err) =>
			if err
				next err
			else
				if content.length < 141
					@sendTweet content, next
				else
					next "Too long"


	@sendTweet: (tweet, next) ->
		@sendSignedRequest "POST", "https://api.twitter.com/1.1/statuses/update.json?status="+encodeURIComponent(tweet), [
			"oauth_consumer_key"
			"oauth_nonce"
			"oauth_signature_method"
			"oauth_timestamp"
			"oauth_version"
			"oauth_token"
		], {"oauth_token": @tokens.final.oauth_token, "status": tweet}, (err, res) =>
			if err
				next err
			else
				body = ""
				res.on "data", (chunk) ->
					body += chunk.toString()
				res.on "end", () =>
					next null, JSON.parse(body)
					log.info "Successfully tweeted \""+tweet+"\" as "+@tokens.final.screen_name


	@getTimeline: (mode, next) ->
		@loadLastLogin (err) =>
			if err
				next err
			else
				if mode is "mentions"
					url = "https://api.twitter.com/1.1/statuses/user_timeline.json"
				else if mode is "direct_messages"
					url = "https://api.twitter.com/1.1/direct_messages.json"
				else # If no specific mode: Use the default timeline
					url = "https://api.twitter.com/1.1/statuses/home_timeline.json"

				@sendSignedRequest "GET", url, [
					"oauth_consumer_key"
					"oauth_nonce"
					"oauth_signature_method"
					"oauth_timestamp"
					"oauth_version"
					"oauth_token"
				], {"oauth_token": @tokens.final.oauth_token}, (err, res) =>
					if err
						next err
						console.log err
					else
						body = ""
						res.on "data", (chunk) ->
							body += chunk.toString()
						res.on "end", () ->
							next null, JSON.parse(body)


	@getStreamingTimeline: (mode, next) ->
		@loadLastLogin (err) =>
			if err
				next err
			else
				additionalInfos =
					"oauth_token": @tokens.final.oauth_token

				if mode is "mentions"
					additionalInfos["with"] = "user"

				@sendSignedRequest "GET", "https://userstream.twitter.com/1.1/user.json", [
					"oauth_consumer_key"
					"oauth_nonce"
					"oauth_signature_method"
					"oauth_timestamp"
					"oauth_version"
					"oauth_token"
				], additionalInfos, (err, res) =>
					if err
						next err
					else
						data = ""
						res.on "data", (chunk) ->
							if not chunk.toString().match /^\r\n$/
								if str = chunk.toString().match /(.+)(\r\n)+$/
									next null, data+str[1]
									data = ""
								else
									data += chunk.toString()
						res.on "end", () ->
							next new Error "Stream closed"

	@getTweet: (id, next) =>
		@loadLastLogin (err) =>
			if err
				next err
			else
				@sendSignedRequest "GET", "https://api.twitter.com/1.1/statuses/show/"+id+".json", [
					"oauth_consumer_key"
					"oauth_nonce"
					"oauth_signature_method"
					"oauth_timestamp"
					"oauth_version"
					"oauth_token"
				], {"oauth_token": @tokens.final.oauth_token}, (err, res) =>
					if err
						next err
					else
						data = ""
						res.on "data", (chunk) ->
							data += chunk.toString()
						res.on "end", () ->
							next null, data

	@retweet: (id, next) =>
		@loadLastLogin (err) =>
			if err
				next err
			else
				@sendSignedRequest "POST", "https://api.twitter.com/1.1/statuses/retweet/"+id+".json", [
					"oauth_consumer_key"
					"oauth_nonce"
					"oauth_signature_method"
					"oauth_timestamp"
					"oauth_version"
					"oauth_token"
				], {"oauth_token": @tokens.final.oauth_token}, (err, res) =>
					if err
						next err
					else
						data = ""
						res.on "data", (chunk) ->
							data += chunk.toString()
						res.on "end", () ->
							next null, data

	@favorite: (id, next) =>
		@loadLastLogin (err) =>
			if err
				next err
			else
				@sendSignedRequest "POST", "https://api.twitter.com/1.1/favorites/create.json?id="+id, [
					"oauth_consumer_key"
					"oauth_nonce"
					"oauth_signature_method"
					"oauth_timestamp"
					"oauth_version"
					"oauth_token"
				], {"oauth_token": @tokens.final.oauth_token, "id": id}, (err, res) =>
					if err
						next err
					else
						data = ""
						res.on "data", (chunk) ->
							data += chunk.toString()
						res.on "end", () ->
							next null, data


	@delete: (id, next) =>
		@loadLastLogin (err) =>
			if err
				next err
			else
				@sendSignedRequest "POST", "https://api.twitter.com/1.1/statuses/destroy/"+id+".json", [
					"oauth_consumer_key"
					"oauth_nonce"
					"oauth_signature_method"
					"oauth_timestamp"
					"oauth_version"
					"oauth_token"
				], {"oauth_token": @tokens.final.oauth_token}, (err, res) =>
					if err
						next err
					else
						data = ""
						res.on "data", (chunk) ->
							data += chunk.toString()
						res.on "end", () ->
							next null, JSON.parse data
