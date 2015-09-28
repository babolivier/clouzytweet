BaseView = require '../lib/base_view'

module.exports = class ColumnView extends BaseView
	el: 'body.application'
	template: require('./templates/column')

	tweets: []

	getTweets: (mode) ->
		switch
			when "timeline" then url = "user/timeline"
			when "mentions" then url = "user/mentions"
			when "dm" then url = "user/dm"
			else url = "user/timeline"
		$.ajax
			url: url
			method: "GET"
			dataType: "json"
			complete: (xhr) =>
				switch xhr.status
					when 200
						for tweet in xhr.responseJSON
							@tweets.push(tweet.text)

	getRenderData: ->
		console.log @tweets
		tweets = @tweets