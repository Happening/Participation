Db = require 'db'
Plugin = require 'plugin'

exports.onInstall = !->
	# set the counter to 0 on plugin installation
	log "Participate server installed called"

exports.client_init = !->
	log "Participate server init called"
	Db.shared.remove 'queries'
	Db.personal().remove 'seeds'
	Db.personal().remove 'up'

exports.client_new = (d) !->	
	id = Db.shared.incr 'queryId'
	log "New query added (" + id + ")"
	Db.shared.set 'queries', id,
		title: d.title
		text: d.text
		repliesId: 0
		replies: null
		status: 3
		user: Plugin.userId() #waarom werkt Plugin serverside ook? magic!

exports.client_reply = (parent, reply, user) !->
	query = Db.shared.ref 'queries', parent
	commentId = query.incr('repliesId')
	replies = query.ref 'replies'
	replies.set commentId,
		text: reply,
		user: user,
		votes: 0
	exports.client_up parent, commentId

exports.client_seed = (queryId, seed) !->
	s = Db.personal().createRef 'seeds'
	s.set queryId, seed

exports.client_up = (queryId, replyId) !->
	#set voted to personal space
	up = Db.personal().createRef 'up'
	# args = path.concat([(v) -> !v])
	# value = up.modify (v) -> !v
	up.modify queryId, replyId, (v) -> !v
	voted = up.get queryId, replyId

	#increase vote in shared (if you haven't already)
	reply = Db.shared.ref 'queries', queryId, 'replies', replyId
	if voted
		reply.modify 'votes', (v) -> v+1
	else	
		reply.modify 'votes', (v) -> v-1

exports.client_status = (queryId, givenStatus) !->
	query = Db.shared.ref 'queries', queryId
	query.modify 'status', (v) -> givenStatus

exports.client_delete = (queryId) !->
	Db.shared.remove 'queries', queryId