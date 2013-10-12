'use strict'

request = require 'request'
Q = require 'q'
util = require 'util'
{EventEmitter} = require 'events'

module.exports = class OpenStageSsh extends EventEmitter

	constructor: (@hostname = 'openstage', @password = '', @debug = false) ->
		@url = "https://#{@hostname}/page.cmd"
		Q.longStackSupport = @debug
		@request = request.defaults
			jar: true
			rejectUnauthorized: false
			url: @url

	createFormAuthData : ->
		method: 'POST'
		form:
			page_submit: 'WEBMp_Admin_Login'
			lang: 'de'
			AdminPassword: @password

	createFormData: (enable) ->
		method: 'POST'
		form:
			page_submit: 'WEBM_Admin_SecureShell'
			lang: 'de'
			'ssh-enable': enable
			'ssh-password': if enable then @password else null
			'ssh-timer-connect': @connectTime
			'ssh-timer-session': @sessionTime

	createStatusParams: ->
		qs:
			page: 'WEBM_Admin_SecureShell'
			lang: 'de'

	createLogoutParams: ->
		qs:
			user: 'none'
			lang: 'de'

	switchSsh: (enable) ->
		Q.nfcall(@request, @createFormData(enable)).then (results) =>
			resp = results[0]
			body = results[1]
			if resp.statusCode isnt 200
				throw new Error "Something went wrong, request to enable SSH failed."
			success = body.match(/class=.success/i)?
			if success and @debug
				if enable
					console.log "Enabled SSH for #{@sessionTime} Minutes. You can log in within #{@connectTime} Minutes."
				else
					console.log "Disabled SSH."
			else if @debug
				console.log "Request was successful but no success message was found. Therefore SSH status is unknown."
				console.log "This can be the case if you're using a firmware version I don't know. Contact me in this case."

			success: success
			url: "ssh://admin@#{@hostname}/"
			password: @password
			connectTime: @connectTime
			sessionTime: @sessionTime


	_queryState: ->
		params = @createStatusParams()
		Q.nfcall(@request, params).then (results) ->
			body = results[1]
			match = body.match /name=\Wssh-enable\W[^>]*(checked)/i
			match?[1] is 'checked'

	_failHandler: (err) ->
		console.error "Failure!"
		throw err

	_resetReminder: ->
		clearTimeout(@timeoutConnect) if @timeoutConnect
		clearTimeout(@timeoutSession) if @timeoutSession

	_setReminder: ->
		@_resetReminder()

		@timeoutConnect = setTimeout =>
			@emit "connectTimeout", @hostname
		, @connectTime * 60 * 1000
		
		@timeoutSession = setTimeout =>
			@emit "sessionTimeout", @hostname
		, @sessionTime * 60 * 1000

	login: ->
		Q.nfcall(@request, @createFormAuthData()).then (results) ->
			if results[0].statusCode isnt 200
				throw new Error "Request error, status code was #{results[0].statusCode}!"
			if results[1].match(/Authentication failed/i)
				throw new Error "Authentication error, wrong password for user 'admin'?"
			

	logout: ->
		Q.nfcall(@request, @createLogoutParams()).then (results) ->
			if results[0].statusCode isnt 200
				throw new Error "Error logging out!"

	getState: (callback) ->
		@login()
			.then( => @_queryState() )
			.catch( @_failHandler )
			.finally( => @logout() )
			.done(callback)

	enable: (@connectTime = 10, @sessionTime = 60, callback) ->
		if typeof @connectTime is 'function'
			callback = @connectTime 
			@connectTime = 10
		@login().then( => 
			@_setReminder()
			@switchSsh(true) )
		.finally( => @logout() )
		.catch( @_failHandler )
		.done(callback)

	disable: (callback) ->
		@login().then( => 
			@switchSsh(false) 
			@_resetReminder())
		.finally( => @logout() )
		.catch( @_failHandler )
		.done(callback)



