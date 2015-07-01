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
Obs = require 'obs'

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

	Dom.section !->
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
							Box: 'bottom'
						Dom.div !->
							Dom.style
								Flex: 1
								padding: '20px 8px'
								position: 'relative'
							
							if status is 2 then Dom.style color: '#aaa'
							Dom.h3 query.get('title')
							if status is 2 then Dom.last().style 'color': '#aaa'
							Dom.text query.get('text')
							Dom.onTap !-> Page.nav query.key() # argument adds /key() to the url
						if Plugin.userIsAdmin()
							Dom.div !->
								Dom.style
									Box: 'vertical right'
									marginTop: '20px'
								Dom.div !->
									Dom.style
										Flex: 1
										Box: 'middle'
										marginRight: '10px'
									require('icon').render(data: '
									question', color: '#666')
									Dom.last().style 'margin-right': '5px'
									Dom.text query.get('repliesId')
								Dom.div !->
									Dom.style
										Box: 'right middle'
										padding: '10px'

									Dom.div !->
										Dom.style
											Box: 'vertical'
											textAlign: 'right'
											fontWeight: 'bold'
											fontSize: '14px'
											textTransform: 'uppercase'
											color: "#bbb"

										mode = query.get('status')-1
										for x,n in [tr("Open"), tr("Closed"), tr("Hidden")]
											Dom.span !->
												Dom.text x
												if mode==n 
													Dom.style color: Plugin.colors().highlight

									Dom.onTap !->
										# modeO.set((modeO.peek()+1)%3)
										newStatus = ((query.peek('status'))%3)+1
										Server.sync 'status', query.key(), newStatus, !->
											#this function toggles the already temporarily. The server side does this for real.
											query.modify 'status', -> newStatus
						else
							Dom.div !->
								Dom.style
									Box: 'vertical right bottom'
									marginTop: '20px'
								if status is 2
									Dom.span !->
										Dom.style
											# position: 'absolute'
											# bottom: '-10px'
											color: '#aaa'
										Dom.text "Closed"
								#render the chat icon anyway
								Dom.div !->
									Dom.style
										Box: 'middle'
										margin: "10px"
									if status is 2 then Dom.style color: '#aaa'
									require('icon').render(data: '
											question', color: if status is 2 then '#aaa' else '#666')
									Dom.last().style 'margin-right': '5px'
									Dom.text query.get('repliesId')
				#seperator
					Dom.div !->
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

						Form.hidden "status", 1
						statusO = Dom.last()
						Dom.div !->
							Dom.style
								Box: 'left middle'
								padding: '10px'

							Dom.span "Initial status:"

							modeO = Obs.create 0
							Dom.div !->
								Dom.style
									Flex: 1
									Box: 'vertical'
									textAlign: 'right'
									fontWeight: 'bold'
									fontSize: '14px'
									textTransform: 'uppercase'
									color: "#bbb"
								
								mode = modeO.get()
								statusO.value( mode + 1 )
								for val,n in [tr("Open"), tr("Closed"), tr("Hidden")]
									Dom.span !->
										Dom.text val
										if mode == n 
											Dom.style color: Plugin.colors().highlight
								Dom.onTap !->
									modeO.set ((mode+1)%3)

						Form.setPageSubmit (d) !->
							if d.title
								Server.call 'new', d
								Page.back()