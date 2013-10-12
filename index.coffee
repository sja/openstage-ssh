util = require 'util'
OpenStageSsh = require './lib/OpenStageSsh'

ossh = new OpenStageSsh('openstage', 'secret', true) # Hostname, Password, debugging

ossh.getState (state) -> 
	console.log "SSH State:" + state # Either true or false

	if state
		ossh.disable -> 
			console.log "Disabled SSH."
		
	else
		ossh.enable 1, 10, (res) -> 
			console.log "Enabled SSH. Settings: " + util.inspect res
			
			ossh.getState (res) -> 
				console.log "3 EXT RESULT=" + res

ossh.on 'connectTimeout', (hostname) ->
	console.log "No new SSH-Connections could be established anymore to #{hostname}."

ossh.on 'sessionTimeout', (hostname) ->
	console.log "SSH was killed automatically on device #{hostname}."



