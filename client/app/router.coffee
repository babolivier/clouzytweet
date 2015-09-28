AppView     = require 'views/app_view'
ColumnView  = require 'views/column_view'

module.exports = class Router extends Backbone.Router

	routes:
		''          : 'main'
		'timeline'  : 'timeline'
		'mentions'  : 'mentions'
		'dm'        : 'dm'

	main: ->
		console.log "dfghjk"
		mainView = new AppView()
		mainView.render()

    timeline: ->
	    console.log "dfghjk"
		mainView = new ColumnView()
		mainView.getTweets("timeline")
		mainView.render()

	mentions: ->
		console.log "dfghjk"
		mainView = new ColumnView()
		mainView.getTweets("mentions")
		mainView.render()