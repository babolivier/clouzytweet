# See documentation on https://github.com/cozy/cozy-db

cozydb = require 'cozydb'

module.exports =
	twitterAccount:
		all: cozydb.defaultRequests.all