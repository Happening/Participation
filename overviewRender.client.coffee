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

renderMenu = (query) !->
	Modal.show "Change status to:", !->
		Dom.style width: '80%'
		Dom.div !->
			Dom.style
				maxHeight: '40%'
				overflow: 'auto'
				_overflowScrolling: 'touch'
				backgroundColor: '#eee'
				margin: '-12px'

			# Plugin.users.iterate (user) !->
			Ui.list !->
				Ui.item !->
					Dom.text tr 'Open'
					Dom.onTap !->
						Server.sync 'status', query.key(), 1, !->
							#this function toggles the already temporarily. The server side does this for real.
							query.modify 'status', -> 1
						Modal.remove()
				Ui.item !->
					# Dom.text if !closed then tr 'Close' else tr 'Open'
					Dom.text tr 'Close'
					Dom.onTap !->
						Server.sync 'status', query.key(), 2, !->
							#this function toggles the already temporarily. The server side does this for real.
							query.modify 'status', -> 2
						Modal.remove()
				Ui.item !->
					# Dom.text if !closed then tr 'Close' else tr 'Open'
					Dom.text tr 'Hide'
					Dom.onTap !->
						Server.sync 'status', query.key(), 3, !->
							#this function toggles the already temporarily. The server side does this for real.
							query.modify 'status', -> 3
						Modal.remove()												
				Ui.item !->
					Dom.style
						color: Plugin.colors().highlight
					Dom.text tr 'Delete'
					Dom.onTap !->
						Modal.remove()
						Modal.confirm "Delete participation", "Are you sure you want to remove the participation?", !->
							Server.sync 'delete', query.key(), !->
								Db.shared.remove 'queries', query.key()	
	, null
	, ['cancel', tr("Cancel")]	

exports.render = ->
	statusText = ['Open', 'Open', 'Closed', 'Hidden']
	statusColor = ['#aaa', Plugin.colors().bar, Plugin.colors().highlight, '#ddd']
	statusColorDark = ['#999', '#005CA0', Plugin.colors().highlight, '#ddd']

	Dom.section !->
		Dom.style
			box: 'middle'
		if not Db.shared.get 'queries'
			Dom.h4 "No participations yet."
		else
			nrP = 0
			Db.shared.iterate 'queries', (query) !->
				#if hidden, skip (unless we're admin)
				if query.get('status') isnt 3 or Plugin.userIsAdmin()
					++nrP
					Dom.div !->
						status = query.get('status') #0 = open, 1 = closed, 2 = hidden
						Dom.style
							box: 'middle'
							position: 'relative'
							display: 'flex'
						Dom.div !->
							Dom.style
								width: '100%'
								padding: '20px 8px'
								# minHeight: '50px'
							
							if status is 2 then Dom.style color: '#aaa'
							Dom.h3 query.get('title')
							if status is 2 then Dom.last().style 'color': '#aaa'
							Dom.text query.get('text')
							Dom.onTap !-> Page.nav query.key() # argument adds /key() to the url
						if Plugin.userIsAdmin()
							Dom.div !->
								Dom.style
									display: 'flex'
									flexDirection: 'column'
									justifyContent: 'flex-end'
									alignItems: 'flex-end'
									margin: "10px 5px"
								Dom.div !->
									Dom.style
										display: 'flex';
										alignItems: 'center'
									require('icon').render(data: '
									question', color: '#666')
									Dom.last().style 'margin-right': '5px'
									Dom.text query.get('repliesId')
								Dom.div !->
									Dom.cls "button"
									Dom.style
										width: '55px'
										textAlign: 'center'
										backgroundColor: statusColor[status]
									Dom.text tr statusText[status]
									Dom.onTap !->
										renderMenu( query )
						else
							#render the chat icon anyway
							Dom.div !->
								Dom.style
									display: 'flex';
									alignItems: 'center'
									margin: "10px"
									width: "50px"
								if status is 2 then Dom.style color: '#aaa'
								require('icon').render(data: '
										question', color: if status is 2 then '#aaa' else '#666')
								Dom.last().style 'margin-right': '5px'
								Dom.text query.get('repliesId')
							if status is 2
								Dom.p !->
									Dom.style
										position: 'absolute'
										bottom: '-10px'
										right: '10px'
										color: '#aaa'
									Dom.text "Closed"
				#seperator
					Dom.div !->
						Dom.style
							# marginTop: '20px'
							# marginBottom: '12px'
						Form.sep()
			if nrP is 0
				#No participations are added or visible.
				Dom.h4 "No participations yet..."
	#add 'add query'
		if Plugin.userIsAdmin()
			Dom.div !->
				Dom.style
					Flex: 1
					padding: '18px 8px'
					color: Plugin.colors().highlight

				Dom.text tr '+ Add participation'
				radio = []
				Dom.onTap !->
					Page.nav !->
						selection = null
						Dom.css
							".pressed":
								backgroundColor: "#f00 !important"
						Form.input
							name: 'title'
							text: 'Title'
						Form.input
							name: 'text'
							text: 'Optional description'
						# for i in [1..3]
						# 	Dom.div !->
						# 		Dom.cls "button"
						# 		Dom.cls "hoi"
						# 		Dom.get().prop("id", "button")
						# 		Dom.get().prop("name", "buttonName")
						# 		Dom.style
						# 			width: '55px'
						# 			textAlign: 'center'
						# 			backgroundColor: statusColor[i]
						# 		radio[i-1] = Dom.get()
						# 		log JSON.stringify radio
						# 		Dom.text tr statusText[i]
						# 		Dom.onTap !->
						# 			log JSON.stringify Dom.get()
									
						# 			selection.style 'background-color': statusColorDark[i]
						Form.setPageSubmit (d) !->
							if d.title
								Server.call 'new', d
								Page.back()