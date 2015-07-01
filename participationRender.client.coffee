Db = require 'db'
Dom = require 'dom'
Ui = require 'ui'
{tr} = require 'i18n'
Rnd = require 'rand'
Plugin = require 'plugin'
Form = require 'form'
Page = require 'page'
Server = require 'server'
Modal = require 'modal'

exports.render = (queryId) ->
	query = Db.shared.ref 'queries', queryId
	seed = Db.personal.get 'seeds', queryId

	#if this query happens to be hidden, go back (unless we're admin)
	if query.get('status') is 3 and !Plugin.userIsAdmin()
		Page.back()

	#make RND with seed if we have it already
	r = new Rnd.Rand(seed)
	if !seed
		Server.send 'seed', queryId, r.seed

	Page.setTitle query.get 'title'

	if Plugin.userIsAdmin()
		Page.setActions
			icon: 'trash'
			label: 'remove photo'
			action: !->
				Modal.confirm null, "Remove participation?", !->
					Server.sync 'delete', queryId, !->
						Db.shared.remove 'queries', queryId
					Page.back()

	Dom.section !->
		Dom.div !->
			Dom.style
				margin: "0px 10px"
			Dom.h1 query.get('title')
			Dom.text query.get('text')
			if query.get('status') is 2
				Dom.h4 "This participation is closed. You can view the results."

		query.iterate 'replies', (reply) !->
			up = Db.personal.ref('up')

			Dom.div !->
				Dom.style
					minHeight: '50px' #minimum height of the upvote thingy
					Box: 'left middle'
					margin: '15px 0px'
				Dom.div !->
					already = up.get queryId, reply.key()
					color = if already then Plugin.colors().highlight else '#666'
					Dom.style
						color: color
						width: '50px'
						padding: '5px'
						Box: 'vertical center'
					if query.get('status') isnt 2						
						Dom.div !->
							Dom.style
								fontSize: '24px'
								paddingTop: if !Plugin.userIsAdmin() then '9px' else 'inherit'
							Dom.text '▲'							
						if Plugin.userIsAdmin
							Dom.div !->
								Dom.text reply.get('votes')
					else 
						Dom.div !->
							Dom.style
								paddingTop: '10px'
							Dom.text reply.get('votes')
					Dom.onTap !->
						Server.sync 'up', queryId, reply.key(), !->
							#this function toggles the already temporarily. The server side does this for real.
							up.modify queryId, reply.key(), (v) -> !v
							reply.incr 'votes', if already then -1 else 1

				Form.vSep()
				Dom.last().style
					"align-self": "stretch"
					"margin": "15px 0px"
					"min-height": "30px"

				Dom.div !->
					Dom.style
						Flex: 1
						padding: '5px 10px'
					Dom.text reply.get('text')
			Form.sep()
		, (reply) -> if query.get('status') is 2 or Plugin.userIsAdmin() then -reply.get 'votes' else r.randn()

		#add Add comment
		if query.get('status') isnt 2
			Dom.div !->
				Dom.style
					marginTop: '5px'
					padding: '15px 8px 10px 18px'
					color: Plugin.colors().highlight	

				Dom.text tr '+ Add reply'
				Dom.onTap !->
					Modal.prompt tr('Your reply'), (d) !->
						if d then Server.call 'reply', queryId, d, Plugin.userId()
