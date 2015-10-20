AppView     = require 'views/app_view'
ColumnView  = require 'views/column_view'

module.exports = class Router extends Backbone.Router

	routes:
		''          : 'main'
		'timeline'  : 'timeline'
		'mentions'  : 'mentions'
		'dm'        : 'dm'

	main: ->
        mainView = new AppView()
        mainView.render()

    timeline: ->
        console.log "dfghjk"

    mentions: ->
        columnView = new ColumnView()
        columnView.getTweets("mentions")

    dm: ->
        console.log "here we are"