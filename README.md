openstage-ssh
=============

Enables OpenStage Phone SSH shell temporarily via WBM.

```coffeescript
util = require 'util'
OpenStageSsh = require 'OpenStageSsh'

ossh = new OpenStageSsh('openstage', 'secret', true) # Hostname, Password, debugging

ossh.getState (state) -> 
	console.log "SSH State:" + state # Either true or false

	if state
		ossh.disable -> 
			console.log "Disabled SSH."
		
	else
		ossh.enable 10, 60, (res) -> # Enable logins for 10 Minutes, sessions for 60 Minutes
			console.log "Enabled SSH. Settings: " + util.inspect res
			
			ossh.getState (res) -> 
				console.log "3 EXT RESULT=" + res

ossh.on 'connectTimeout', (hostname) ->
	console.log "No new SSH-Connections could be established anymore to #{hostname}."

ossh.on 'sessionTimeout', (hostname) ->
	console.log "SSH was killed automatically on device #{hostname}."

```
